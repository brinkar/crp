require "crp"

fork do
	CRP.run do
		channel "test", :type => :server, :host => "localhost", :port => 19283
		write "test", "Test from server"
		read "test"
		puts "Server stopping"
		stop
	end
end

CRP.run do
	timeout 1
	channel "test", :type => :client, :host => "localhost", :port => 19283
	puts "Server writes: #{read "test"}"
	write "test", nil
	puts "Client stopping"
	stop
end
