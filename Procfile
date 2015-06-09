server: ruby server.rb "*" 10101
client: rackup -p 8000 -b "use Rack::Static, :index => 'index.html'; run Rack::File.new('.')"
