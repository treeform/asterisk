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
sys = require('sys')
exec = require('child_process').exec

read_config = ->
    try
        text = fs.readFileSync(process.env.HOME + "/.asterisk.json", 'utf8')
    catch e
        print "could not read ~/.asterisk.json"
    try
        return JSON.parse(text)
    catch e
        print "could not parse ~/.asterisk.json"
    return {'username': 'admin', 'password': '123'}

config = read_config()

mimeTypes = {
    "html": "text/html",
    "png": "image/png",
    "js": "text/javascript",
    "css": "text/css"};

begins_with = (str, frag) -> str.match(new RegExp "^#{frag}")?
ends_with = (str, frag) -> str.match(new RegExp "#{frag}$")?
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


lint = (s, filename) ->
    if ends_with(filename, ".py")
        pylint(s, filename)
    if ends_with(filename, ".coffee")
        coffeemake(s, filename)


pylint = (s, filename) ->
    print "running lint", s, filename
    command = "pylint #{filename} -f parseable -r n --disable=W0621"
    exec command, (error, stdout, stderr) ->
        marks = for line in stdout.split("\n")
            m = line.match(/.*:(\d*):\s\[(.*)\]\s(.*)/)
            if m
                mark =
                    line: m[1]
                    tag: m[2]
                    text: m[3]
            else
                continue
        console.log marks
        s.emit 'marks-push',
            filename: filename
            marks: marks


coffeemake = (s, filename) ->
    print "running coffee", filename
    command = "coffee -c #{filename}"
    exec command, (error, stdout, stderr) ->
        marks = []
        for line in stderr.split("\n")
            m = line.match("line (.+):(.*)")
            print m, line
            if m
                marks.push
                    line: m[1]
                    tag: 'error'
                    text: m[2]

            m = line.match(",(.*), starting on line (.*)")
            print m, line
            if m
                marks.push
                    line: m[2]
                    tag: 'error'
                    text: m[1]


        console.log marks
        s.emit 'marks-push',
            filename: filename
            marks: marks

io.sockets.on 'connection', (socket) ->
    iden = gen_iden()
    clients[iden] = Client(iden)
    socket.emit('connected', {iden: iden})
    print iden, ":", "connected"

    loggedin = false

    socket.on 'auth', (auth) ->
        if auth.username == config.username and auth.password == config.password
            socket.emit "loggedin"
            loggedin = true
        else
            socket.emit 'error-push',
                message: "invalid username or password"
                kind: "ribbon"

    error = (msg) ->
        socket.emit 'error-push',
            message: msg
            kind: "ribbon"

    open = (req) ->
        print "open", req.filename
        if fs.existsSync(req.filename) and fs.statSync(req.filename).isFile()
            file_data = fs.readFileSync(req.filename, 'utf8')
            socket.emit 'open-push',
                filename: req.filename
                data: file_data
            lint(socket, req.filename)
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
        return error("not logged in") if not loggedin
        open(req)

    socket.on 'save', (req) ->
        return error("not logged in") if not loggedin
        print "save", req.filename
        try
            fs.writeFileSync(req.filename, req.data, 'utf8')
            lint(socket, req.filename)
        catch e
            socket.emit 'error-push',
                message: "error #{e} writing '#{req.filename}'"
                kind: "ribbon"

    socket.on 'suggest', (req) ->
        return error("not logged in") if not loggedin
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
