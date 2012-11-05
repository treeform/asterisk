# Asterisk websoket server

# <- find file names
# <- find in files
# <- open file
# <- save file
# -> file changed 
# -> check results

io = require('socket.io').listen(8080)

io.sockets.on 'connection', (socket) ->
  socket.emit('news', { hello: 'world' })
  socket.on 'keypress', (data) ->
    console.log(data);

