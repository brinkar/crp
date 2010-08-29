module CRP
	
	class Sequence
	
		def initialize(context)
			@context = context
			@processes = []
		end
	
		def process(&block)
			@processes << block
		end
		
		def run
			@processes.each do |block|
				@context.instance_eval &block
			end
		end
	
	end

end
