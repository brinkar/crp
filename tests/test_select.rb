require "test/unit"
require "crp"

class TestSelect < Test::Unit::TestCase

	def test_reads
		out = ""
		CRP.run do
			process do
				2.times do 
					select do
						read("a") { |data| out << data }
						read("b") { |data| out << data }
					end
				end
			end
			process { write "a", "a"; write "b", "b"; stop }
		end
		assert_equal out, "ab"
		out = ""
		CRP.run do
			process { write "a", "a"; write "b", "b"; stop }		
			process do
				2.times do 
					select do
						read("a") { |data| out << data }
						read("b") { |data| out << data }
					end
				end
			end
		end
		assert_equal out, "ab"
	end	
	
	def test_writes
		out = ""
		CRP.run do
			process do
				2.times do 
					select do
						write "a", "a"
						write "b", "b"
					end
				end
			end
			process { out << read("a"); out << read("b"); stop }
		end
		assert_equal out, "ab"
		out = ""
		CRP.run do
			process { out << read("a"); out << read("b"); stop }		
			process do
				2.times do 
					select do
						write "a", "a"
						write "b", "b"
					end
				end
			end
		end
		assert_equal out, "ab"		
	end
	
	def test_read_write
		out = ""
		CRP.run do
			process do
				2.times do 
					select do
						read("a") { |data| out << data }
						write "b", "b"
					end
				end
			end
			process { write("a", "a"); out << read("b"); stop }
		end
		assert_equal out, "ab"
	end
	
	def test_write_read
		out = ""
		CRP.run do
			process do
				2.times do 
					select do
						write "a", "a"					
						read("b") { |data| out << data }
					end
				end
			end
			process { out << read("a"); write("b", "b"); stop }
		end
		assert_equal out, "ab"	
	end
	
	def test_skip
		out = ""
		CRP.run do
			process do
				2.times do 
					select do
						read("a") {|d| out << d}
						skip
					end
				end
				stop
			end
			process { write("a", "a") }
		end
		assert_equal out, "a"
	end
	
	def test_timeout
		out = ""
		CRP.run do
			process do
				2.times do 
					select do
						read("a") {|d| out << d}
						timeout 0.1
					end
				end
				stop
			end
			process { write("a", "a"); write("a", "a") }
		end
		assert_equal out, "aa"	
	end

end
