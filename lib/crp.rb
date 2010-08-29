require "eventmachine"
require "fiber"

require "crp/context"
require "crp/sequence"

module CRP

	def self.run(&block)
		EM.run do
			context = Context.new &block
			context.run
		end
	end
	
end
