# Asterisk websocket server

# <- find file names
# <- find in files
# <- open file
# <- save file
# -> file changed
# -> check results
print = (args...) -> console.log args...

gen_iden = -> Math.random().toString(32)[2..]

io = require('socket.io').listen(8080)
events = require('events')
path = require('path')
child_process = require('child_process')
fs = require('fs')
http = require('http');

mimeTypes = {
    "html": "text/html",
    "png": "image/png",
    "js": "text/javascript",
    "css": "text/css"};

#options =
#  key: fs.readFileSync('secure/privatekey.pem'),
#  cert: fs.readFileSync('secure/certificate.pem')

server = http.createServer (req, res) ->
    try
        print("client/"+req.url[1..])
        filename = "client/" + req.url[1..].split("?")[0]
        buffer = fs.readFileSync(filename)
        print "buffer", buffer.length
        #mimeType = mimeTypes[path.extname(filename).split(".").pop()]
        #res.writeHead(200, {'Content-Type': mimeType} )
        res.end(buffer)
    catch e
        print e
        buffer = fs.readFileSync("client/asterisk.html")
        buffer = buffer.toString().replace("$rand", gen_iden())
        res.end(buffer)
server.listen(1988)

findem = (dir, s) ->
    ev = new events.EventEmitter()
    if s.length > 0
        s = "-name '*#{s}*'"
    ls = child_process.exec(
        "find #{dir} #{s} -maxdepth 5")
    files = []
    ls.data = ""
    ls.stdout.on "data", (data) ->
        ls.data += data
    ls.on "exit", ->
        for line in ls.data.split("\n")
            if line.length > 0
                files.push(line)
        ev.emit("end", files)
    return ev

clients = {}

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
                message: "filename '#{req.filename}' not found, saveing will create new file"
                kind: "ribbon"
            # push an empty file up
            socket.emit 'open-push',
                filename: req.filename
                data: ""

    socket.on 'keypress', (data) ->
        print iden, ":", "keypress", data

    socket.on 'open', (req) ->
        open(req)

    socket.on 'save', (req) ->
        print "save", req.filename
        try
            fs.writeFileSync(req.filename, req.data, 'utf8')
        catch e
            socket.emit 'error-push',
                message: "error #{e} writing '#{req.filename}'"
                kind: "ribbon"

    socket.on 'suggest', (req) ->
        s = req.query
        dir = req.directory
        if s and s[0] == "/"
            dir = s[0..s.lastIndexOf("/")-1]
            s = s[s.lastIndexOf("/")+1..]
        print "s", s, "dir", dir
        finder = findem(dir, s)
        finder.on 'end', (files) ->
            files = (f for f in files when not f.match ("\.pyc|~|\.git|\.bzr$"))
            files.sort (a, b) ->
                al = a.length
                bl = b.length
                #al -= 20 if a in recent_files
                #bl -= 20 if b in recent_files
                return al - bl
            files = files[0..30]
            print files
            socket.emit "suggest-push",
                files: files.reverse()

    socket.on 'disconnect', ->
        print iden, ":", "disconnected"
