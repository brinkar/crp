puts "This example does not work yet, sorry"
exit

require "crp"

# TODO: We need named processes.
# TODO: Process initial data, also channels. Eg. 5 different left channels. Can be done with eg. "down#{i}"
=begin
CRP.process "philosopher" do |id|
	eat = 0
	loop do
		write "down", true
		select do
			write("left", true) { write "right", true }
			end
			write("right", true) { write "left", true }
		end
		eat += 1
		select do # TODO: Could be nice to be able to reuse selects
			write("left", true) { write "right", true }
			end
			write("right", true) { write "left", true }
		end
		write "up", true
	end
end

CRP.process "fork" do # TODO: Make sure channels are correct
	loop do
		select do
			read("left") { read "left" } # TODO: Not sure these are correct
			read("right") { read "right" }			
		end
	end
end

CRP.process "security" do |steps|
	max = 4
	n_sat_down = [0]
	steps.each do |step|
		select do
			if n_sat_down[0] < max
				5.times do |i|
					read("down") { n_sat_down += 1 }
				end
			end
			5.times do |i|
				read("up") { n_sat_down -= 1 }
			end
		end
	end
end

CRP.run do
	process "security", 1000
	5.times { |i| process "philosopher", i }
	5.times { |i| process "fork", i }
end
=end

