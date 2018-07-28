require "socket"
require "base64"

class Connection
  Message = Struct.new(:message, :requester, :send_to)
  attr_reader :socket, :host, :port, :uuid

  def initialize(host: "192.168.49.1", port: 8962)
    @host, @port = host, port
    @connected = false
    @uuid = nil
    @queue = []

    connect
    return self
  end

  def connect
    Thread.new do
      begin
        puts "Connecting"
        @socket = Socket.tcp(host, port, connect_timeout: 5)
        @connected = true
        puts "Connected"
        authenticate
        puts "Authenticated"
      rescue SocketError => e
        p e
      end

      loop do
        break if not connected?
        while(@queue.size > 0)
          process_queue
          puts "-> 1"
        end
        sleep 0.01
      end

      @socket.close if @socket
    end
  end

  def process_queue
    message = @queue.shift
    if message
      write(message.message)
      data = read
      if message.send_to
        message.requester.send(message.send_to, data)
      else
        puts data
      end

      return true
    else
      return false
    end
  end

  def connected?
    @connected
  end

  def authenticate
    @uuid = read
    write(@uuid)
  end

  def request(message = "", requester = nil, send_to = nil)
    @queue << Message.new(message, requester, send_to)
  end

  def write(string)
    @socket.puts(Base64.strict_encode64(string))
    @socket.puts "\r\n"
  end

  def read(max_length = 2048)
    return Base64.decode64(@socket.recv(max_length))
  end
end