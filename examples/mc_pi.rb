require "crp"

CRP.process "mc_pi" do |n, out|
	sum = 0
	n.times do
		sum += 1 if rand**2.0 + rand**2.0 < 1.0
	end
	result = 4.0*sum / n
	write out, result
end

CRP.process "mc_pi_serial" do |n|
	channel "result"
	process "mc_pi", :args => [n, "result"]
	puts "Result:\t\t#{read "result"}"
	stop
end

CRP.process "mc_pi_parallel" do |n, forked, workers|

	channel "jobs", (forked ? :server : :standard)
	channel "results", (forked ? :server : :standard)	
	
	workers.times do
		process :fork => forked do
			b = read "jobs"
			process "mc_pi", :args => [b, "results"]
		end
	end

	batch = n / workers
	workers.times { write "jobs", batch }
	sum = 0.0
	workers.times { sum += read "results" }
	result = sum / workers
	puts "Result:\t\t#{result}"
	stop
end

n = 10000000
k = 10
cores = 2

puts "=========\n* Running serial version"
t = Time.now
CRP.run { process "mc_pi_serial", :args => [n] }
t_serial = Time.now - t
puts "Time used:\t#{t_serial.round(2)} s"

puts "---------\n* Running unforked parallel version"
t = Time.now
CRP.run { process "mc_pi_parallel", :args => [n, false, k] }
t_par1 = Time.now - t
puts "Time used:\t#{t_par1.round(2)} s"
puts "Speedup:\t#{((t_serial/t_par1)/cores).round(2)}"

puts "---------\n* Running forked parallel version"
t = Time.now
CRP.run { process "mc_pi_parallel", :args => [n, true, k] }
t_par2 = Time.now - t
puts "Time used:\t#{t_par2.round(2)} s" 
puts "Speedup:\t#{((t_serial/t_par2)/cores).round(2)}"
puts "========="

