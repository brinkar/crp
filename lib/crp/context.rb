module CRP

	class Context

		attr_reader :processes
	
		def initialize(&block)
			@channels = {}
			@processes = EM::Queue.new
			process &block if block_given?
		end
		
		def run
			@processes.pop do |process|
				case process
				when Array
					process, data = process
					process.resume data if process.alive?
				when Fiber
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
		end
	
		def stop
			EM.stop_event_loop
		end
		
		def skip
			@processes.push Fiber.current
		end
		
		def sequence(&block)
			seq = Sequence.new self
			seq.instance_eval &block
			seq.run
		end
		
		def write(channel, data)
			@channels[channel] = EM::Queue.new unless @channels[channel].is_a?(EM::Queue)
			@channels[channel].push [Fiber.current, data]
			Fiber.yield
		end
		
		def read(channel)
			@channels[channel] = EM::Queue.new unless @channels[channel].is_a?(EM::Queue)
			current_fiber = Fiber.current
			@channels[channel].pop do |event|
				fiber, data = event
				@processes.push [current_fiber, data]				
				@processes.push fiber
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

	end
	
end
