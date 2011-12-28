# Copyright: Hiroshi Ichikawa <http://gimite.net/en/>
# Lincense: New BSD Lincense

require 'rubygems'
require 'json'
require "thread"

$LOAD_PATH << File.dirname(__FILE__) + "/lib"
require "web_socket"

Thread.abort_on_exception = true

if ARGV.size != 2
  $stderr.puts("Usage: ruby sample/chat_server.rb ACCEPTED_DOMAIN PORT")
  exit(1)
end

server = WebSocketServer.new(
  :accepted_domains => [ARGV[0]],
  :port => ARGV[1].to_i())
puts("Server is running at port %d" % server.port)
connections = []
history = [nil] * 20

game = [[],[],[]]

server.run() do |ws|
  begin
    
    puts("Connection accepted")
    ws.handshake()
    que = Queue.new()
    connections.push(que)

    ws.send(game.to_json())
    
    thread = Thread.new() do
      while true
        message = que.pop()
        ws.send(message)
        puts("Sent: #{message}")
      end
    end
    
    while data = ws.receive()
      puts("Received: #{data}")

      move = JSON.parse(data)
      game[move['x']][move['y']] = move['marker']
      data = game.to_json()

      for conn in connections
        conn.push(data)
      end

      history.push(data)
      history.shift()
    end
    
  ensure
    connections.delete(que)
    thread.terminate() if thread
    puts("Connection closed")
  end
end
