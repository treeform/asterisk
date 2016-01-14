# Asterisk webws server

# <- find file names
# <- find in files
# <- open file
# <- save file
# -> file changed
# -> check results

#io = require('ws.io').listen(8080)


HTTP_PORT = 1988
WSS_PORT  = 1977


WebSocketServer = require('ws').Server
events = require('events')
path = require('path')
child_process = require('child_process')
fs = require('fs')
http = require('http');
sys = require('sys')
exec = require('child_process').exec


print = (args...) -> console.log args...
gen_iden = -> Math.random().toString(32)[2..]


read_config = ->
    try
        text = fs.readFileSync(process.env.HOME + "/.asterisk.json", 'utf8')
    catch e
        print "could not read ~/.asterisk.json"
    try
        return JSON.parse(text)
    catch e
        print "could not parse ~/.asterisk.json"
    process.exit()
config = read_config()


mimeTypes = {
    "html": "text/html",
    "png": "image/png",
    "js": "text/javascript",
    "css": "text/css"};


begins_with = (str, frag) -> str.match(new RegExp "^#{frag}")?
ends_with = (str, frag) -> str.match(new RegExp "#{frag}$")?
server = http.createServer (req, res) ->
    try
        print("client/"+req.url[1..])
        filename = "client/" + req.url[1..].split("?")[0]
        buffer = fs.readFileSync(filename)
        #print "buffer", buffer.length
        #mimeType = mimeTypes[path.extname(filename).split(".").pop()]
        #res.writeHead(200, {'Content-Type': mimeType} )
        res.end(buffer)
    catch e
        print e
        buffer = fs.readFileSync("client/asterisk.html")
        buffer = buffer.toString().replace("$rand", gen_iden())
        res.end(buffer)
server.listen(HTTP_PORT)


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


file_exists = (filename) ->
    fs.existsSync(filename) and fs.statSync(filename).isFile()


lint = (s, filename) ->

    if ends_with(filename, ".py")
        pylint(s, filename)
    if ends_with(filename, ".coffee")
        coffeemake(s, filename)

    gitdiff(s, filename)

pylint = (s, filename) ->
    print "running lint", s, filename
    command = "pylint #{filename} -f parseable -r n -d W0621,C0111,C0103,W0403,R0911,R0912,R0913,R0914"
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
        s.safeSend 'marks-push',
            layer: "error"
            filename: filename
            marks: marks


coffeemake = (s, filename) ->
    print "running coffee", filename
    path = filename[...filename.lastIndexOf("/")]
    command = "cd #{path}; coffee -cm #{filename}"
    console.log "$", command
    exec command, (error, stdout, stderr) ->
        marks = []
        #print "stderr", stderr.split("\n")
        for line in stderr.split("\n")
            m = line.match("line (.+):(.*)")
            #print "::1", [m, line]
            if m
                marks.push
                    line: m[1]
                    tag: 'error'
                    text: m[2]

            m = line.match(",(.*) on line (.*)")
            #print "::2", [m, line]
            if m
                marks.push
                    line: m[2]
                    tag: 'error'
                    text: m[1]

            m = line.match(".*:(.*):.*: error: (.*)")
            print "::3", [m, line]
            if m
                marks.push
                    line: parseInt(m[1])
                    tag: 'error'
                    text: m[2]
        print "coffee marks", marks
        s.safeSend 'marks-push',
            layer: "errors"
            filename: filename
            marks: marks

gitdiff = (s, filename) ->
    print "running git diff",
    dir = filename.match(/(.*\/)[^\/]/)[1]

    command = "cd '#{dir}'; git diff --no-color -U0 #{filename}"
    exec command, (error, stdout, stderr) ->
        marks = []

        make_mark = (regex) ->
            m = line.match(regex)
            if m
                print "GIT", line
                for i in [0...parseInt(m[2] or "1")]
                    marks.push
                        line: parseInt(m[1]) + i
                        tag: 'change'
                        text: ""

        for line in stdout.split("\n")
            make_mark("@@ \\-\\d+\\,\\d+? \\+(\\d+),(\\d+) @@")
            make_mark("@@ \\-\\d+\\ \\+(\\d+),(\\d+) @@")
            make_mark("@@ \\-\\d+\\ \\+(\\d+) @@")

        s.safeSend 'marks-push',
            layer: "diff"
            filename: filename
            marks: marks


wss = new WebSocketServer(port:WSS_PORT)

wss.on 'connection', (ws) ->

    loggedin = false
    filename = null

    # alert the editor when file changes
    watching_filename = null
    watch = () ->
        if watching_filename
            fs.unwatchFile(watching_filename)
        watching_filename = filename
        if filename and file_exists(filename)
            fs.watchFile filename, (curr, prev) ->
                if filename and file_exists(filename)
                    file_data = fs.readFileSync(filename, 'utf8')
                    ws.safeSend 'open-push',
                        filename: filename,
                        data: file_data
                    lint(ws, filename)

    ws.safeSend = (msg, kargs) ->
        try
            ws.send JSON.stringify
                msg: msg
                kargs: kargs
        catch e
            console.log(e)

    error = (msg) ->
        ws.safeSend 'error-push',
            message: msg
            kind: "ribbon"

    open = (req) ->
        filename = req.filename
        print "open", filename
        if file_exists(filename)
            file_data = fs.readFileSync(filename, 'utf8')
            ws.safeSend 'open-push',
                filename: filename
                data: file_data
            lint(ws, filename)
            watch()
        else
            ws.safeSend 'error-push',
                message: "filename '#{req.filename}' not found, saveing will create new file"
                kind: "ribbon"
            # push an empty file up
            ws.safeSend 'open-push',
                filename: filename
                data: ""

    ws.on 'message', (packet_str) ->
        packet = JSON.parse(packet_str)
        msg = packet.msg
        kargs = packet.kargs
        console.log "got message", msg, kargs

        switch msg

            when "auth"
                if kargs.username == config.username and kargs.password == config.password
                    ws.safeSend "loggedin"
                    loggedin = true
                else
                    ws.safeSend 'error-push',
                        message: "invalid username or password"
                        kind: "ribbon"

            when "open"
                 if not loggedin
                    return error("not logged in")
                 open(kargs)

            when 'save'
                return error("not logged in") if not loggedin
                filename = kargs.filename
                print "save", filename
                try
                    fs.writeFileSync(filename, kargs.data, 'utf8')
                    lint(ws, filename)
                    watch()
                catch e
                    ws.safeSend 'error-push',
                        message: "error #{e} writing '#{filename}'"
                        kind: "ribbon"

            when  'suggest'
                if not loggedin
                    return error("not logged in")

                s = kargs.query
                console.log "s", kargs.query
                dir = kargs.directory
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
                    ws.safeSend "suggest-push",
                        files: files.reverse()

    iden = gen_iden()
    ws.safeSend('connected', {iden: iden})
