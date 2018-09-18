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
    when "download"
      write("Received download")
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
      write("PEN: 1.0\nX: 0\nY: 0\nX_ENDSTOP: true\nY_ENDSTOP: false")
    when "stop"
      write("HALTING")
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
puts "Server listening..."
loop do
  Client.new(@server.accept)
end

@server.close if @server