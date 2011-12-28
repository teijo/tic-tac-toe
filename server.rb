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

game = [[nil, nil, nil],[nil, nil, nil],[nil, nil, nil]]

def reset(g)
  puts("Game reset")
  g.each { |row| row.fill(nil) }
end

def isOver(g)
  for row in g
    for cell in row
      if cell == nil
        return false
      end
    end
  end
  return true
end

reset(game)

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
      if game[move['x']][move['y']] == nil
        game[move['x']][move['y']] = move['marker']
      end
      data = game.to_json()

      for conn in connections
        conn.push(data)
      end

      if isOver(game)
        reset(game)
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
