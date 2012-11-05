requestAnimFrame = window.requestAnimationFrame or 
        window.webkitRequestAnimationFrame or
        window.mozRequestAnimationFrame or
        window.oRequestAnimationFrame  or
        ((cb) -> window.setTimeout(cb, 1000 / 60))

print = (args...) -> console.log(args...)

keybord_key = (e) ->
    k = []
    if e.metaKey
        k.push("meta")
    if e.ctrlKey
        k.push("ctrl")
    if e.altKey
        k.push("alt")
    if e.shiftKey
        k.push("shift")
        
    if e.which == 9
        k.push("tab")
    else if e.which == 13
        k.push("enter")
    else if e.which == 27
        k.push("esc")
    else
        k.push(String.fromCharCode(e.which).toLowerCase())
    return k.join("-")


specs =
    python:
        NAME: "python"
        FILE_TYPES: "py pyw".split()
        CASESEN_SITIVE: true
        MULTILINE_STR: true
        DELIMITERS: " (){}[]<>+-*/%=\"'~!@#&$^&|\\?:;,."
        KEYWORD_PREFIX: '&'
        ESCAPECHAR: "\\"
        QUOTATION_MARK1: "\""
        QUOTATION_MARK2: "\'"
        LINE_COMMENT: "#"
        PAIRS1: "()"
        PAIRS2: "[]"
        PAIRS3: "{}"
        KEY1: "break continue elif else for if pass return while and not or in".split(" ")
        KEY2: "class def import from lambda".split(" ")
        KEY3: "except finally raise try".split(" ")

class Tokenizer

    constructor: ->
        @token_cache = {}
        @spec = specs.python
        
    tokenize: (@line) ->
        if @token_cache[@line]
            return @token_cache[@line]
        return @token_cache[line] = @tokenize_line(@line)
        
    tokenize_line: ->
        line = @line
        spec = @spec
        colored = []
        norm = 0
        old_c = " "
        i = 0
        while i < line.length
            c = line[i]
                
           
            if c == spec.QUOTATION_MARK1
                start = i
                i += 1
                while c != line[i] and i < line.length 
                    if line[i] == spec.ESCAPECHAR
                        i += 1
                    i += 1
                colored.push(["string",line[start..i]])
                i += 1
                continue
            
            if c == spec.LINE_COMMENT
                colored.push(["comment",line[i..]])
                break
              
            if old_c in spec.DELIMITERS
                skip = @keywords(c, i, line, colored, spec)
                if skip?
                    i = skip
                    continue
                    
            last = colored[colored.length-1]    
            if not last? or last[0] != "text"
                colored.push(["text", c])
            else
                last[1] += c
            old_c = c
            i += 1
       
        out = []
        for [cls, words] in colored
            out.push("<span class='#{cls}'>#{words}</span>")
        out.push("\n")
        
        return [colored, out.join("")]
        
    keywords: (c, i, line, colored, spec) ->
        for k in [0..6]
            if spec["KEY"+k]?
                for t in spec["KEY"+k]
                    if c == t[0]
                        w = line[i..i+t.length-1]
                        last = line[i+t.length]
                        if not last?
                            last = " "
                        if w == t and last in spec.DELIMITERS
                            colored.push(["key"+k, w])
                            i += t.length
                            return i
        return 

class Connection

    constructor: ->
        host = window.document.location.host.replace(/:.*/, '')
        @socket = io.connect("ws://#{host}:8080")
        @socket.on 'news', (data) ->
            console.log(data)
            @socket.emit('my other event', { my: 'data' })
         
    
class Editor

    constructor: ->
        
        @con = new Connection()
        
        # grab common elements
        @$doc = $(document) 
        @$win = $(window)
        @$holder = $(".holder")
        @$pad = $(".pad")
        @$ghost = $(".ghost")
        @$highlight = $(".highlight")

        # grab careat
        @$caret_line = $("#caret-line")
        @$caret_text = $("#caret-text")
        @$caret_char = $("#caret-char")

        # updates       
        @$doc.keydown (e) =>
            @update()
            return @key(e)
        @$doc.keyup (e) =>
            @update()
            return true
        @$doc.keypress (e) =>
            @update()
            return true
        @$doc.mousedown => 
            @mousedown=true
            @update()
        @$doc.mousemove => 
            if @mousedown
                @update()
        @$doc.mouseup =>
            @mousedown = false
            @update()
        @$win.resize(@update)
        @$doc.click(@update)
        
        # keeps all the highlight state
        @lines = []
        @tokenizer = new Tokenizer()
        
        # does not update if not changed        
        @old_text = ""
        @old_caret = [0,0]
        
        @keymap = 
            'esc': @reset
            'alt-l': => @show_promt("#load")
            'alt-g': => @show_promt("#goto")
            'alt-a': => @show_promt("#command")
            'alt-s': => @show_promt("#search")
            
          
        @reset()
          
        # loop that redoes the work when needed
        @requset_update = true
        @workloop()
        
    reset: =>
        $(".prompt").hide()
        $("#pad").focus()
        
    show_promt: (p) ->
        $(p).show()
        $(p+" input").focus()
        print "load promt", p
        
    update: =>
        @requset_update = true

    real_update: ->
        if performance?
            now = performance.now()
        
        # adjust hight and width of things
        h = @$win.height()
        w = @$win.width()
        @$holder.height(h)
        @$holder.width(w)
        @$pad.width(w)
        @$ghost.width(w)
        @$highlight.width(w)
        
        # get the current text
        text = @$pad.val()
        
        # high light if it has changed
        if @old_text != text
            @old_text = text
            lines = text.split("\n")
            start = 0
            for line, i in lines
                end = start + line.length + 1
                if @lines[i]?
                    oldline = @lines[i] 
                    oldline[1] = start
                    oldline[2] = end
                    if oldline[3] != line
                        [colored, html] = @tokenizer.tokenize(line)   
                        oldline[3] = line
                        $("#line"+i).html(html)
                else
                    [colored, html] = @tokenizer.tokenize(line)
                    @lines.push([i, start, end, line])
                    out = []
                    out.push("<span id='line#{i}'>")
                    out.push(html)
                    out.push("</span>")
                    @$ghost.append(out.join(""))
                start = end
            while lines.length < @lines.length
                l = @lines.pop()
                $("#line"+l[0]).remove()
                
    
        # update caret if it has changed caret 
        at = @$pad[0].selectionStart
        end = @$pad[0].selectionEnd
        
        if @old_caret != [at, end]
            @old_caret = [at, end]
            if at == end
                for line in @lines
                    if line[1] <= at < line[2]
                        if at != line[1]
                            caret_text = text[line[1]..at-1]
                        else
                            caret_text = ""
                        #print "cur on ", line[0], caret_text 
                        top = $("#line"+line[0]).position().top + 100
                        @$caret_text.html(caret_text)
                        @$caret_char.html("&#x2588;")
                        @$caret_line.css("top", top)
            else
                if at > end
                    [at, end] = [end, at]
                for line in @lines
                    if line[1] <= at < line[2]
                        if at != line[1]
                            caret_text = text[line[1]..at-1]
                        else
                            caret_text = ""
                        top = $("#line"+line[0]).position().top + 100
                        @$caret_text.html(caret_text)
                        @$caret_line.css("top", top)
                        @$caret_char.html(text[at..end-1])
        
        h = @$ghost.height()
        @$pad.height(h+100)
        if performance?
            print "update", performance.now()-now, "ms"
    
    key: (e) ->
        key = keybord_key(e)
        print "key press", key
        @con.socket.emit("keypress", key)
        if @keymap[key]?
            @keymap[key]()
            e.stopPropagation()
            return false
        return true
        
    workloop: =>
        if @requset_update
            @real_update() 
            @requset_update = false
        requestAnimFrame(@workloop)
    
$ new Editor()
