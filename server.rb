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
             #rows
  vectors = [[[0,0],[0,1],[0,2]],
             [[1,0],[1,1],[1,2]],
             [[2,0],[2,1],[2,2]],
             #cols
             [[0,0],[1,0],[2,0]],
             [[0,1],[1,1],[2,1]],
             [[0,2],[1,2],[2,2]],
             #diagonals
             [[0,0],[1,1],[2,2]],
             [[2,0],[1,1],[0,2]]]

  for v in vectors
    a = g[v[0][0]][v[0][1]]
    b = g[v[1][0]][v[1][1]]
    c = g[v[2][0]][v[2][1]]
    if (a == 'x' or a == 'o') and a == b and a == c
      return true
    end
  end

  over = true
  for row in g
    for cell in row
      if cell == nil or cell == 0
        over = false
      end
    end
  end

  return over
end

if !isOver(
  [['x','x','x'],
   [ 0 , 0 , 0 ],
   [ 0 , 0 , 0 ]]
  )
    puts('fail 1')
end

if !isOver(
  [[ 0 , 0 , 0 ],
   ['x','x','x'],
   [ 0 , 0 , 0 ]]
  )
    puts('fail 2')
end

if !isOver(
  [[ 0 , 0 , 0 ],
   [ 0 , 0 , 0 ],
   ['x','x','x']]
  )
    puts('fail 3')
end

if !isOver(
  [['x', 0 , 0 ],
   [ 0 ,'x', 0 ],
   [ 0 , 0 ,'x']]
  )
    puts('fail 4')
end

if !isOver(
  [[ 0 , 0 ,'x'],
   [ 0 ,'x', 0 ],
   ['x', 0 , 0 ]]
  )
    puts('fail 5')
end

if !isOver(
  [['x', 0 , 0 ],
   ['x', 0 , 0 ],
   ['x', 0 , 0 ]]
  )
    puts('fail 6')
end

if !isOver(
  [[ 0 ,'x', 0 ],
   [ 0 ,'x', 0 ],
   [ 0 ,'x', 0 ]]
  )
    puts('fail 7')
end

if !isOver(
  [[ 0 , 0 ,'x'],
   [ 0 , 0 ,'x'],
   [ 0 , 0 ,'x']]
  )
    puts('fail 8')
end

if !isOver(
  [['x','o','x'],
   ['o','o','x'],
   ['x','x','o']]
  )
    puts('fail 9')
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
