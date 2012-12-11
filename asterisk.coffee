# Asterisk websoket server

# <- find file names
# <- find in files
# <- open file
# <- save file
# -> file changed 
# -> check results
print = (args...) -> console.log args...

gen_iden = -> Math.random().toString(32)[2..]

io = require('socket.io').listen(8080)
fs = require('fs')

clients = {}

last_filename = "foo"

class Client
    constructor: (@idne) ->


io.sockets.on 'connection', (socket) ->
    iden = gen_iden()
    clients[iden] = Client(iden)
    socket.emit('connected', {iden: iden})
    print iden, ":", "connected"  
    
    open = (req) ->
        print "open", req.filename
        if fs.existsSync(req.filename)
            file_data = fs.readFileSync(req.filename, 'utf8')
            socket.emit 'open-push', 
                filename: req.filename
                data: file_data
            last_filename = req.filename
        else
            socket.emit 'error-push', 
                message: "filename '#{req.filename}' not found"
                kind: "ribbon" 
    
    if last_filename
        open(filename: last_filename)

    socket.on 'keypress', (data) ->
        print iden, ":", "keypress", data

    socket.on 'open', (req) ->
        open(req)
        
    socket.on 'save', (req) ->
        print "save", req.filename
        fs.writeFileSync(req.filename, req.data, 'utf8')

    socket.on 'disconnect', ->
        print iden, ":", "disconnected"  
