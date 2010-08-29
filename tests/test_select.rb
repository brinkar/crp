require "test/unit"
require "crp"

class TestCRP < Test::Unit::TestCase

	def test_read
		out = ""
		CRP.run do
			process do
				2.times do 
					select do
						read "a" { |data| out << data }
						read "b" { |data| out << data }
					end
				end
			end
			process { write "a", "a"; write "b", "b"; stop }
		end
		assert_equal out, "ab"
	end	
	
	def test_write
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
	end
	
	def test_skip
	
	end
	
	def test_timeout
	
	end
	
	def test_mix
		
	end

end
