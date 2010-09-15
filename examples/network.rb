require "crp"

CRP.run do
	n = 10
	host, port = "localhost", 19283
	channel "test", :server
	n.times do |i|
		process :fork => true do
			write "test", "Process #{i}"
		end
	end
	n.times { puts read "test" }
	stop
end
