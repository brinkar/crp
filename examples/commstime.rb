require "crp"

N = 5000

CRP.run do

	process do
		loop do
			write "a", 0
			c = read "c"
		end	
	end
	
	process do
		loop do
			msg = read "a"
			write "b", msg
			write "d", msg
		end	
	end

	process do
		loop do
			write "c", read("b")
		end	
	end
		
	# Consumer process
	process do
		read "d"
		t1 = Time.now
		N.times { read "d" }
		dt = Time.now - t1
		t_chan = dt / (4*N)
		puts "Time: #{dt} s", "Time pr. channel: #{(t_chan*1e6).round(3)} us (#{t_chan} s)"
		stop
	end

end
