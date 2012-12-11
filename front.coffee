requestAnimFrame = window.requestAnimationFrame or
        window.webkitRequestAnimationFrame or
        window.mozRequestAnimationFrame or
        window.oRequestAnimationFrame  or
        ((cb) -> window.setTimeout(cb, 1000 / 60))

print = (args...) -> console.log(args...)

KEY_MAP = 
    9: "tab"
    13: "enter"
    27: "esc"
    37: "left"
    38: "up"
    39: "right"
    40: "down"

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

    if e.which of KEY_MAP
        k.push(KEY_MAP[e.which])
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
        
    colorize_line: ->
        line = @line
        spec = @spec
        colored = []
        norm = 0
        old_c = " "
        i = 0
        while i < line.length
            c = line[i]


            if c == spec.QUOTATION_MARK1 or c == spec.QUOTATION_MARK2
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
            
        return colored 
        
    tokenize_line: ->
        colored = @colorize_line()
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
        @socket.on 'connected', (data) ->
            console.log("connected with", data.iden)
            #@socket.emit('my other event', { my: 'data' })
        
        @socket.on 'open-push', (res) -> editor.open_cmd.open_push(res)
        @socket.on 'suggest-push', (res) -> editor.open_cmd.open_suggest_push(res)
        
        @socket.on 'error-push', (error) ->
            print "error-push", error.message
        
        
esc = ->
    editor.focus()
    
class GotoLine

    constructor: ->
        @$box = $("#goto-box")
        @$input = $("#goto-input")
        @$input.keyup (e) =>
            if keybord_key(e) == "enter"
                @enter()
                
    envoke: =>
        esc()
        @$box.show()
        @$input.focus()
        @$input[0].selectionStart = 0
        @$input[0].selectionEnd = @$input.val().length
            
    enter: ->       
        esc()
        line = parseInt(@$input.val())
        if line > 0
            editor.goto_line(line)

class OpenFile

    constructor: ->
        @$box = $("#open-box")
        @$input = $("#open-input")
        @$sug = $("#open-sugest")
        @$input.keyup @keyup

    keyup: (e) =>
        print @$input.val()
        key = keybord_key(e)
        print key
        if key == "enter"
            @enter()
        else if key == "up" or key == "down"
            chosen = @$sug.find(".sug-highlight")
            if chosen.size() == 0
                chosen = @$sug.children().last()
            else
                if key == "up"
                    next = chosen.prev()
                else
                    next = chosen.next()
                if next.size() > 0
                    chosen.removeClass("sug-highlight")
                    next.addClass("sug-highlight")
                    chosen = next
            chosen.addClass("sug-highlight")
            @$input.val(chosen.text())
        else
            editor.con.socket.emit("suggest", query:@$input.val(), directory:".")
                
    envoke: =>
        esc()
        @$box.show()
        @$input.focus()
        @$input[0].selectionStart = 0
        @$input[0].selectionEnd = @$input.val().length
            
    enter: ->       
        esc()
        filename = @$input.val()
        print "open", filename
        editor.con.socket.emit("open", filename:filename)
    
    open_push: (res) ->
        print "open-push", res.filename
        editor.filename = res.filename
        $("title").html(res.filename)
        editor.$pad.val(res.data)
        editor.update()
        
    open_suggest_push: (res) ->
        print res.files
        @$sug.children().remove()
        search = @$input.val()
        for file in res.files
            file = file.replace(search,"<b>#{search}</b>")
            @$sug.append("<div class='sug'>#{file}<div>")

search = (pad) ->
    esc()
    $("#search-box").show()
    $("#search-input").focus()
    selected_word = pad.edit.getSelection()
    if selected_word
        $("#search-input").val(selected_word)

command = ->
    $("#command-box").show()
    $("#command-input").focus()
    


$("#command-box").hide()
$("#command-input").keyup (e) ->
    editor = current_pad.edit
    if e.which == ENTER
        $input = $(e.currentTarget)
        query = $input.val()
        if not query
            return
        js = CoffeeScript.compile(query)
        eval(js)
        esc()

last_pos = null
last_query = null
$("#search-box").hide()
$("#search-input").keyup (e) ->
    editor = current_pad.edit
    m.clear() for m in marked
    marked = []

    $input = $(e.currentTarget)
    query = $input.val()
    if not query or query.length == 1
        return
    cursor = editor.getSearchCursor(query)
    while cursor.findNext()
        t = editor.markText(cursor.from(), cursor.to(), "searched")
        marked.push(t)

    if e.which == ENTER
        cur_pos = editor.getCursor()
        if last_query != query
            last_pos = null

        if e.shiftKey
            cursor = editor.getSearchCursor(query, last_pos-1 or cur_pos-1)
            # backwards
            if not cursor.findPrevious()
                # wrap lines
                cursor = editor.getSearchCursor(query)
                if not cursor.findPrevious()
                    return
        else
            cursor = editor.getSearchCursor(query, last_pos or cur_pos)
            # forward
            if not cursor.findNext()
                #warp lines
                cursor = editor.getSearchCursor(query)
                if not cursor.findNext()
                    return

        editor.setSelection(cursor.from(), cursor.to())
        last_query = query
        last_pos = cursor.to()

$("#replace-input").keyup (e) ->
    editor = current_pad.edit
    m.clear() for m in marked
    marked = []
    $input = $(e.currentTarget)
    text = $("#search-input").val()
    replace = $input.val()

    return if not text

    if false and e.which == ENTER
        # replace all
        cursor = editor.getSearchCursor(text)
        while cursor.findNext()
            cursor.replace(replace)

    if e.which == ENTER
        # replace all
        cursor = editor.getSearchCursor(text, off, false)
        if e.shiftKey
            c = cursor.findPrevious()
        else
            c = cursor.findNext()
        if c
            cursor.replace(replace)
            editor.setSelection(cursor.from(), cursor.to())



class MiniMap

    constructor: ->
        print "mini map"
        @$minimap_outer = $("#mini-map")
        @$minimap = $("#mini-map .inner")
        
        
    real_update: ->
        @$minimap.css
            height: editor.height
            width: 200
            #top: -700
        
            
    
class Editor

    constructor: ->
        window.editor = @
        @con = new Connection()
        @filename = "foo"
        
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
            e.preventDefault()
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

        #@minimap = new MiniMap()

        @goto_cmd = new GotoLine()
        @open_cmd = new OpenFile()
        
        
        @keymap = 
            'esc': @focus
            'ctrl-g': @goto_cmd.envoke
            'ctrl-l': @open_cmd.envoke
            'ctrl-s': @save
            
            
            #'alt-g': => @show_promt("#goto")
            #'alt-a': => @show_promt("#command")
            #'alt-s': => @show_promt("#search")
            
          
        @focus()
          
        # loop that redoes the work when needed
        @requset_update = true
        @workloop()
    
    save: =>
        @con.socket.emit "save",
            filename: @filename
            data: @$pad.val()

    focus: =>
        $("div.popup").hide()
        @$pad.focus()
        @update()
                
    show_promt: (p) ->
        $(p).show()
        $(p+" input").focus()
        print "load promt", p

    update: =>
        @requset_update = true

    real_update: ->
        if performance? and performance.now?
            now = performance.now()

        # adjust hight and width of things

        @height = @$win.height()
        @width = @$win.width()
        @$holder.height(@height)
        @$holder.width(@width)
        @$pad.width(@width)
        @$ghost.width(@width)
        @$highlight.width(@width)

        # get the current text
        text = @$pad.val()
        
        set_line = (i, html) =>
            $("#line#{i}").html(html)
            $("#mm#{i}").html(html) if @minimap
            
        add_line = (i, html) =>
            @$ghost.append("<span id='line#{i}'>#{html}</span>")
            @minimap.$minimap.append("<span id='line#{i}'>#{html}</span>") if @minimap

        rm_line = (i) =>
            $("#line#{i}").remove()
            $("#mm#{i}").remove() if @minimap

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
                        set_line(i, html)
                else
                    [colored, html] = @tokenizer.tokenize(line)
                    @lines.push([i, start, end, line])
                    add_line(i, html)
                start = end
            while lines.length < @lines.length
                l = @lines.pop()
                rm_line(l[0])
    
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
                        @$caret_char.html("&nbsp;")
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

        @full_height = @$ghost.height()
        @$pad.height(@full_height+100)
        if performance? and performance.now?
            print "update", performance.now()-now, "ms"
    
        @minimap?.real_update()
    
    goto_line: (line_num) ->
        line = @lines[line_num] ? @lines[@lines.length - 1]
        print line[1]
        @$pad[0].selectionStart = line[1]
        @$pad[0].selectionEnd = line[1]
        @scroll_line(line[0])

    scroll_line: (line_num) ->
        line = @lines[line_num] ? @lines[@lines.length - 1]
        y = @get_line_y(line[0])
        y -= @$win.height()/2
        print "scroll to y", y
        @$holder.animate(scrollTop: y)

    get_line_y: (line_num) ->
        top = $("#line"+line_num).position().top + 100
        return top

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

$ ->
    new Editor()

