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
turn = 0

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
    
    ws.handshake()
    que = Queue.new()
    connections.push(que)

    data = {"state"=>game,"turn"=>turn,"players"=>connections.length}

    idx = connections.index(que)
    puts("Connection accepted ##{idx}")
    data["move"] = (turn%2 == idx)
    data["no"] = idx

    ws.send(data.to_json())
    
    thread = Thread.new() do
      while true
        message = que.pop()
        ws.send(message)
        puts("Sent: #{message}")
      end
    end
    
    while data = ws.receive()
      puts("Received: #{data}")

      # position can change if some players leave
      idx = connections.index(que)
      if turn%2 != idx
        puts("Data from wrong player ##{idx}")
        next
      end

      move = JSON.parse(data)
      if game[move['x']][move['y']] == nil
        turn += 1

        marker = 'o'
        if turn%2 == 0
          marker = 'x'
        end

        game[move['x']][move['y']] = marker
      end
      data = {"state"=>game,"turn"=>turn,"players"=>connections.length}

      for conn in connections
        idx = connections.index(conn)
        data["move"] = (turn%2 == idx)
        data["no"] = idx
        conn.push(data.to_json())
      end

      if isOver(game)
        # round-robin, put first to last
        connections = connections.concat(connections.shift(1))
        reset(game)
        turn = 0
      end
    end
    
  ensure

    idx = connections.index(que)

    connections.delete(que)
    thread.terminate() if thread

    if idx < 2
      reset(game)
      turn = 0
      data = {"state"=>game,"turn"=>turn,"players"=>connections.length}

      for conn in connections
        idx = connections.index(conn)
        data["move"] = (turn%2 == idx)
        data["no"] = idx
        conn.push(data.to_json())
      end
    end

    puts("Connection ##{idx} closed, #{connections.length} left")
  end
end
