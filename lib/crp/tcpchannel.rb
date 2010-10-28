require 'yajl'
require "socket"

module CRP

	module TCP
	
		def self.stanza(type, id, data = nil)
			hash = {:type => type, :id => id, :data => data}
			Yajl::Encoder.encode(hash)
		end
	
		def self.generate_id
			rand(99_99_99)
		end
	
		class ServerConnection < EM::Connection

			def initialize(channel)
				super()
				@channel = channel
				@parser = Yajl::Parser.new(:symbolize_keys => true)
				@parser.on_parse_complete = Proc.new do |data|
					channel.handle(self, data)
				end
			end
			
			def post_init
				@channel.add_connection self
			end
			
			def unbind
				@channel.remove_connection self
			end

			def receive_data(data)
				@parser << data
			end
				
		end
		
		class ChannelServer < Channel
		
			attr_reader :host, :port
		
			def initialize(host = nil, port = nil)
				super()
				host ||= "localhost"
				port ||= 0
				server = EM.start_server host, port, TCP::ServerConnection, self
				@port, @host = Socket.unpack_sockaddr_in(EM.get_sockname(server))
				@connections = []
				@stopdef = nil
			end
		
			def handle(con, msg)
				type, id, data = msg[:type], msg[:id], msg[:data]
				case type
				when "stop"
					CRP.context.stop
				when "write"
					if reader?
						con.send_data CRP::TCP.stanza(:response, id)
						@readq.shift.call data
					else
						@writeq << [data, Proc.new do
							con.send_data CRP::TCP.stanza(:response, id)
						end]
					end
				when "read"
					if writer?
						data, cb = @writeq.shift
						con.send_data CRP::TCP.stanza(:response, id, data)
						cb.call
					else
						@readq << Proc.new do |data|
							con.send_data CRP::TCP.stanza(:response, id, data)
						end
					end
				end
			end
			
			def add_connection(con)
				@connections << con
			end
			
			def remove_connection(con)
				@connections.delete con
				if @connections.empty? and @stopdef
					@stopdef.done(self)
				end
			end
			
			def stop(stopdef)
				@stopdef = stopdef
				if @connections.empty?
					@stopdef.done self
				else
					@connections.each do |c|
						c.send_data CRP::TCP.stanza(:stop, CRP::TCP.generate_id)
						c.close_connection_after_writing
					end
				end
			end
			
		end
		
		class ClientConnection <  EM::Connection
		
			def initialize(channel)
				super()
				@channel = channel
				@response_queue = {}
				@parser = Yajl::Parser.new(:symbolize_keys => true)
				@parser.on_parse_complete = Proc.new do |data|
					handle(data)
				end
			end
		
			def receive_data(data)
				@parser << data
			end
			
			def unbind
				@channel.close
			end
			
			def send(type, data = nil, &block)
				id = CRP::TCP.generate_id
				@response_queue[id] = Proc.new do |response|
					block.call response
				end
				send_data CRP::TCP.stanza(type, id, data)
			end
			
			private
			
			def handle(msg)
				type, id, data = msg[:type], msg[:id], msg[:data]
				if type == "stop"
					CRP.context.stop
				else
					if @response_queue.has_key?(id)
						@response_queue[id].call data
					end
				end
			end
		
		end
		
		class ChannelClient
		
			def initialize(host = "localhost", port)
				raise ArgumentError if port.nil?
				@con = EM.connect host, port, ClientConnection, self
				@stopdef = nil
			end
			
			def write(data, &cb)
				@con.send :write, data do
					cb.call
				end
			end
			
			def read(&cb)
				@con.send :read do |data|
					cb.call data
				end
			end
			
			def writer?
			end
		
			def reader?
			end
		
			def cancel_reader(cb)
			end

			def cancel_writer(cb)
			end
			
			def close
				@stopdef.done self if @stopdef
			end
			
			def stop(stopdef)
				@stopdef = stopdef
				@con.send_data CRP::TCP.stanza(:stop, CRP::TCP.generate_id)
				@con.close_connection_after_writing
			end
		
		end
	
	end
	
end
