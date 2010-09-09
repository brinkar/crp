module CRP

	class Context
	
		def initialize(&block)
			@channels = {}
			@processes = EM::Queue.new
			process &block if block_given?
		end
		
		# TODO: Move to a scheduler class, so that the context is clear
		def run
			@processes.pop do |process|
				if process.is_a?(Array) and process.size == 2
					process, data = process
					process.resume data if process.alive?
				elsif process.is_a?(Fiber)
					process.resume if process.alive?
				end
				EM.next_tick { run }
			end
		end
		
		private
		
		def process(name = nil, *args, &block)
			if name
				fiber = Fiber.new do 
					instance_exec *args, &(CRP.processes[name])
				end
			else
				fiber = Fiber.new { instance_eval &block }
			end
			@processes.push fiber
			# TODO: Should we yield and wait for the process to exit before we resume the parent?
			# This method could then be called fork
		end
	
		def stop
			EM.stop_event_loop
		end
		
		def skip
			@processes.push Fiber.current
			yield if block_given?
			Fiber.yield
		end
		
		# TODO: Should it be here?		
		def sequence(&block)
			seq = Sequence.new self
			seq.instance_eval &block
			seq.run
		end
		
		def write(channel, data)
			current_fiber = Fiber.current
			@channels[channel].write data do
				@processes.push current_fiber
			end
			yield if block_given?
			Fiber.yield
		end
		
		def read(channel)
			current_fiber = Fiber.current
			@channels[channel].read do |data|
				yield data if block_given?
				@processes.push [current_fiber, data]		
			end
			Fiber.yield
		end
		
		def timeout(seconds)
			current_fiber = Fiber.current
			start_time = Time.now			
			EM.add_timer seconds do
				end_time = Time.now
				@processes.push [current_fiber, end_time-start_time]
			end
			Fiber.yield
		end
		
		def channel(*names)
			# TODO: Buffering and protocol
			names.each do |name|
				@channels[name] = Channel.new
			end
		end

		def select(&block)
			s = Select.new &block
			current_fiber = Fiber.current
			if r = s.reads.find { |r| @channels[r[:channel]].writer? rescue false }
				read r[:channel], &r[:callback]
			elsif w = s.writes.find { |w| @channels[w[:channel]].reader? rescue false }
				write w[:channel], w[:data], &w[:callback]
			elsif t = s.timer and (tn = Time.now) >= (t[:time] + t[:seconds])
				t[:callback].call (tn-t[:time])
				skip
			elsif sk = s.skipped
				skip &sk[:callback]
			else
				# Wait for something to happen			
				state = {:reads_waiting => [], :writes_waiting => [], :timer => nil}
				s.reads.each do |r|
					cb = @channels[r[:channel]].read do |data|
						cancel_all state
						r[:callback].call data
						@processes.push current_fiber
					end
					state[:reads_waiting] << [r[:channel], cb]
				end
				s.writes.each do |w|
					cb = @channels[w[:channel]].write w[:data] do
						cancel_all state
						w[:callback].call if w[:callback]
						@processes.push current_fiber							
					end								
					state[:writes_waiting] << [w[:channel], cb]					
				end
				if t = s.timer
					state[:timer] = EM.add_timer (t[:time]+t[:seconds]) - Time.now do
						cancel_all state
						end_time = Time.now
						@processes.push [current_fiber, end_time-t[:time]]
					end
				end
				Fiber.yield
			end
		end
		
		# TODO: Make internal to select
		def cancel_all(state)
			state[:reads_waiting].each do |rw|
				channel, cb = rw
				@channels[channel].cancel_reader cb
			end
			state[:writes_waiting].each do |ww|
				channel, cb = ww
				@channels[channel].cancel_writer cb
			end
			EM.cancel_timer state[:timer] if state[:timer]
		end

	end
	
end
