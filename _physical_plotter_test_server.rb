require "socket"
require "base64"
require "securerandom"

class Client
  def initialize(socket)
    @socket = socket
    @uuid = SecureRandom.uuid
    @connected = true
    @authenticated = false

    Thread.new { update }
  end

  def update
    write(@uuid)
    loop do
      if !@authenticated
        if (read == @uuid)
          @authenticated = true
          puts "Client-#{@uuid} Connected"
        else
          write("401")
        end
      else
        parse(read)
      end
    end
  end

  def parse(string)
    return if string.size == 0
    puts "->#{string}"
    case string.split(" ").first
    when "home"
      write("Moving to 0:0")
    when "move"
      axes = string.sub("move", "").strip.split(":")
      write("moving to #{axes.first}:#{axes.last}")
    when "pen_up"
      write("Lifting pen")
    when "pen_down"
      write("Lowering pen")
    when "status"
      write("{\"status\":200, \"data\":{\"xAxis\":100,\"yAxis\":100}}")
    else
      write("Unknown command")
    end
  end

  def read
    Base64.decode64(@socket.recv(2048))
  end

  def write(string)
    @socket.puts(Base64.strict_encode64(string))
    @socket.puts "\r\n"
  end

  def close
    @socket.close
  end
end

@server = TCPServer.new(8962)
loop do
  Client.new(@server.accept)
end

@server.close if @server