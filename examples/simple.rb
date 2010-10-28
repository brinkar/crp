require "crp"

CRP.run do

	n = 10
	channel "test"

	n.times do |i|
		process do
			write "test", "Process #{i}"
		end
	end

	n.times { puts read "test" }

	stop

end
