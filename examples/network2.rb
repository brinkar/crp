require "crp"

CRP.process "commstime" do |forked|

	n = 5000
	channel_type = forked ? :server : :standard

	channel "a", channel_type
	channel "b", channel_type
	channel "c", channel_type
	channel "d", channel_type

	process :fork => forked do
		loop do
			write "a", 0
			c = read "c"
		end	
	end
	
	process :fork => forked do
		loop do
			msg = read "a"
			write "b", msg
			write "d", msg
		end	
	end

	process :fork => forked do
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

[false, true].each do |forked|
	CRP.run { process "commstime", :args => [forked] }
end


