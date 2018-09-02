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
        @machine.status(:error, "Failed to connect to plotter, connection refused [Errno::ECONNREFUSED]")
      rescue SocketError => e
        @connected = false
        @errored = true
        @machine.status(:error, "SocketError: "+e)
      rescue Errno::ETIMEDOUT => e
        @connected = false
        @errored = true
        @machine.status(:error, "Connection timed out [Errno::ETIMEDOUT]")
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
        @machine.status(:error, "Disconnected from plotter [IOError]")

      rescue Errno::ECONNRESET => e
        @connected = false
        @errored = true
        @queue.insert(0, message)
        @machine.status(:error, "Disconnected from plotter, connection reset [Errno::ECONNRESET]")

      rescue Errno::EMFILE => e
        @connected = false
        @error = true
        @queue.insert(0, message)
        @machine.status(:error, "Unable to open socket, to many open files [Errno::EMFILE]")

      rescue Errno::EPIPE => e
        @connected = false
        @errored = true
        @queue.insert(0, message)
        @machine.status(:error, "Disconnected from plotter, broken pipe [Errno::EPIPE]")
      end
    end
  end

  def estop
    @queue.clear
    @queue << Message.new("estop")
    @machine.status(:error, "Attempting to perform an Emergency Stop...")
  end

  def print_it
    events = nil
    if @machine.rcode_events
      events = @machine.rcode_events
    else
      @machine.compiler.reset
      Machine::Compiler::Processor.new(compiler: @machine.compiler, canvas: @machine.canvas)
      events = @machine.compiler.events
    end

    if events.nil? || events.count == 2 # includes Pen up and Home, always.
      @machine.status(:error, "No rcode events, have you plotted?")
    else
      @machine.status(:busy, "Printing from #{events.count} rcode events...")
      events.each do |event|
        if event.x
          request("#{event.type} #{event.x}:#{event.y}")
        else
          request("#{event.type}")
        end
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