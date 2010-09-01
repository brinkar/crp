module CRP

	class Select
	
		attr_reader :reads, :writes, :timer, :skipped
		
		def initialize(&block)
			@reads = []
			@writes = []
			@timer = nil
			@skipped = nil
			instance_eval &block
			# TODO: Detect reads and writes to the same channel. It's a no go!
		end
		
		def read(channel, &block)
			@reads << {:channel => channel, :callback => block}
		end
		
		def write(channel, data, &block)
			@writes << {:channel => channel, :callback => block, :data => data}
		end
		
		def skip(&block)
			@skipped = {:callback => block}
		end
		
		def timeout(seconds, &block)
			@timer = {:time => Time.now, :seconds => seconds, :callback => block}
		end
		
	end
	
end
