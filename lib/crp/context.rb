module CRP

	class Context
	
		def initialize(&block)
			@channels = {}
			@processes = EM::Queue.new
			process &block if block_given?
		end
		
		def run
			@processes.pop do |process|
				if process.is_a?(Array) and process.size == 2
					process, data = process
					process.resume data if process.alive?
#				elsif process.is_a?(Array) and process.size == 3
#					puts process.inspect
#					process, callback, data = process
#					process.resume [callback, data] if process.alive?
				elsif process.is_a?(Fiber)
					process.resume if process.alive?
				end
				EM.next_tick { run }
			end
		end
		
		def to_s
			"Processes: #{@processes.inspect}\nChannels: #{@channels.inspect}"
		end
		
		private
		
		def process(&block)
			fiber = Fiber.new do 
				instance_eval &block
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
		
		def sequence(&block)
			seq = Sequence.new self
			seq.instance_eval &block
			seq.run
		end
		
		def write(channel, data)
			@channels[channel] = Channel.new unless @channels[channel].is_a?(Channel)
			current_fiber = Fiber.current
			@channels[channel].write data do
				@processes.push current_fiber
			end
			yield if block_given?
			Fiber.yield
		end
		
		def read(channel)
			@channels[channel] = Channel.new unless @channels[channel].is_a?(Channel)
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
					@channels[r[:channel]] = Channel.new unless @channels[r[:channel]].is_a?(Channel)
					cb = @channels[r[:channel]].read do |data|
						cancel_all state
						r[:callback].call data
						@processes.push current_fiber
					end
					state[:reads_waiting] << [r[:channel], cb]
				end
				s.writes.each do |w|
					@channels[w[:channel]] = Channel.new unless @channels[w[:channel]].is_a?(Channel)
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

=begin		
		def select(&block)
			s = Select.new &block
			current_fiber = Fiber.current
			# Are any readers ready?
			if reader = s.reads.find { |read| !@channels[read[:channel]].empty? rescue false }
				@channels[reader[:channel]].pop do |data|
					fiber, data = data
					@processes.push [current_fiber, reader[:callback], data]
					@processes.push fiber
				end
			# Are any writers ready?				
			elsif writer = s.writes.find { |write| @channels[write[:channel]].reader? }
				@channels[writer[:channel]].push [current_fiber, writer[:data]]
				@processes.push [current_fiber, writer[:callback], nil]
			# Is there a	timer, and is it ready?
			elsif t = s.timer and Time.now >= (t[:time] + t[:seconds])
				@processes.push [current_fiber, t[:callback], nil]
			# Is there a skip?
			elsif skip = s.skip
				@processes.push [current_fiber, skip[:callback], nil]
			# Well then we have to wait for something to happen...
			else
				waiters = []
				s.reads.each do |reader|
					waiters << @channels[reader[:channel]].wait_for_write do
						@channels[reader[:channel]].pop do |data|
							fiber, data = data
							@processes.push [current_fiber, reader[:callback], data]
							@processes.push fiber
						end
					end
				end
			end
			callback, data = Fiber.yield
			callback.call data if callback
		end
=end

	end
	
end
