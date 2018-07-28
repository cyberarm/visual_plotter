require "socket"
require "base64"

socket = TCPSocket.new("192.168.49.1", 8962)
puts "Connected to socket.peera"
uuid = Base64.strict_decode64(socket.recv(1024).strip)
puts uuid
socket.puts(Base64.strict_encode64(uuid))
socket.puts("\r\n")

loop do
  puts
  print ">"
  input = gets.chomp
  socket.puts(Base64.strict_encode64(input))
  socket.puts("\r\n")

  output = socket.recv(4096)
  p output
  puts Base64.decode64(output)
end
