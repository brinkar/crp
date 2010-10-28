require "crp"

CRP.process "commstime" do

	n = 5000

	channel "a", :server
	channel "b", :server
	channel "c", :server
	channel "d", :server

	process :fork => true do
		loop do
			write "a", 0
			c = read "c"
		end	
	end
	
	process :fork => true do
		loop do
			msg = read "a"
			write "b", msg
			write "d", msg
		end	
	end

	process :fork => true do
		loop do
			write "c", read("b")
		end	
	end
		
	# Consumer process
	process do
		read "d"
		t1 = Time.now
		n.times { read "d" }
		dt = Time.now - t1
		t_chan = dt / (4*n)
		puts "Time: #{dt} s", "Time pr. channel: #{(t_chan*1e6).round(3)} us (#{t_chan} s)"
		stop
	end

end

CRP.run { process "commstime" }


