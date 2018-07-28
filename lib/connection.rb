require "socket"
require "base64"

class Connection
  Message = Struct.new(:message, :requester, :send_to)
  attr_reader :socket, :host, :port, :uuid

  def initialize(host: "192.168.49.1", port: 8962, machine:)
    @host, @port = host, port
    @machine = machine
    @connected = false
    @errored = false
    @uuid = nil
    @queue = []

    connect
    return self
  end

  def connect
    Thread.new do
      begin
        @machine.status(:busy, "Connecting to plotter...")
        @socket = Socket.tcp(host, port, connect_timeout: 5)
        @connected = true
        @machine.status(:busy, "Connected to plotter, authenticating...")
        authenticate
        @machine.status(:okay, "Authenticated to plotter")
      rescue Errno::ECONNREFUSED => e
        @errored = true
        @connected = false
        @machine.status(:error, "Failed to connect to plotter")
      rescue SocketError => e
        @connected = false
        @errored = true
        @machine.status(:error, "SocketError: "+e)
      end

      loop do
        break if not connected?
        while(@queue.size > 0)
          process_queue
        end
        sleep 0.0001
      end

      @socket.close if @socket
    end
  end

  def reconnect
    if !connected? && @errored
      @errored = false
      connect
    else
      @machine.status(:okay, "Aleady connected to plotter")
    end
  end

  def process_queue
    message = @queue.shift
    if message
      begin
        write(message.message)
        data = read
        if message.send_to
          message.requester.send(message.send_to, data)
        else
          puts data
        end
      rescue IOError => e
        @connected = false
        @errored = true
        @queue.insert(0, message)

        reconnect
      rescue Errno::EPIPE => e
        @connected = false
        @errored = true
        @queue.insert(0, message)

        reconnect
      end
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