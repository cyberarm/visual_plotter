require "socket"
require "base64"

class Connection
  attr_reader :socket, :host, :port, :uuid

  def initialize(host: "192.168.49.1", port: 8962)
    @socket = TCPSocket.new(host, port)
    @host, @port = host, port

    authenticate
  end

  def authenticate
    @uuid = read
    write(@uuid)
  end

  def write(string)
    @socket.puts(Base64.strict_encode64(string))
    @socket.puts "\r\n"
  end

  def read(max_length = 2048)
    return Base64.decode64(@socket.recvfrom(max_length))
  end
end