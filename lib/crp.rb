require "eventmachine"
require "fiber"

require "crp/context"
require "crp/sequence"
require "crp/channel"
require "crp/select"

require "crp/tcpchannel"

module CRP

	class << self
	
		def run(&block)
			EM.run do
				context = Context.new &block
				@context.run
			end
		end
	
		def process(name, &block)
			@processes = {} unless @processes.is_a?(Hash)
			@processes[name] = block 
		end
	
		def processes
			@processes
		end
		
		def context=(c)
			@context = c
		end
	
		def context
			@context
		end	
		
	end
	
end
