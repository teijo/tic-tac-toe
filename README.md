Ruby WebSocket multiplayer tic-tac-toe
======================================

A piece of old code found from disk and now archived to Github.

A realtime Ruby WebSocket tic-tac-toe multiplayer game based on
https://github.com/gimite/web-socket-ruby echo server demo.

Running
-------

Startup requires a bit of manual work. You'll need to start the server and
serve the static files separately.

1. Listen any address for connections at port 10101 (port hardcoded to client
   code):

   ```
   ruby server.rb "*" 10101
   ```

2. Serve client code with your favorite oneliner:

   ```
   python -m SimpleHTTPServer 8000
   ```

3. Open http://localhost:8000/ in two or more browser to spectate and play.
