module CRP

	class Channel
		
		def initialize
			@readq = []
			@writeq = []
		end
		
		def write(data, &cb)
			if reader?
				@readq.shift.call(data)
				cb.call			
			else
				@writeq << [data, cb]			
			end
		end
		
		def read(&cb)
			if writer?
				data, wcb = @writeq.shift
				wcb.call
				cb.call data
			else
				@readq << cb
			end
		end
		
		def writer?
			not @writeq.empty?
		end
		
		def reader?
			not @readq.empty?
		end
		
		def cancel_reader(cb)
			@readq.delete(cb)
		end

		def cancel_writer(cb)
			@writeq.delete(cb)
		end
		
	end

end
