# request animation is a function that fires
# when browser is ready to redraw the screen again
# fires around 60fps when tab is open
requestAnimFrame = window.requestAnimationFrame or
        window.webkitRequestAnimationFrame or
        window.mozRequestAnimationFrame or
        window.oRequestAnimationFrame  or
        ((cb) -> window.setTimeout(cb, 1000 / 60))

# nice short cut
print = (args...) -> console.log(args...)

# keyboard system
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
        if navigator.platform.match("Mac")
            k.push("ctrl")
        else
            k.push("meta")
    if e.ctrlKey
        if navigator.platform.match("Mac")
            k.push("meta")
        else
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
    # plain spec highlights strings and quotes and thats it
    plain:
        NAME: "plain"
        FILE_TYPES: []
        CASESEN_SITIVE: true
        MULTILINE_STR: true
        DELIMITERS: " (){}[]<>+-*/%=\"'~!@#&$^&|\\?:;,."
        ESCAPECHAR: "\\"
        QUOTATION_MARK1: "\""
        PAIRS1: "()"
        PAIRS2: "[]"
        PAIRS3: "{}"
        KEY1: []
        KEY2: []
        KEY3: []

    python:
        NAME: "python"
        FILE_TYPES: "py pyw".split(" ")
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

    coffee:
        NAME: "CoffeeScript"
        FILE_TYPES: ["coffee"]
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
        KEY1: "break continue else for if return while and not or in".split(" ")
        KEY2: "class -> => extends new".split(" ")
        KEY3: "catch finally throw try".split(" ")

    html:
        NAME: "html"
        FILE_TYPES: ["html"]
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
        KEY1: "html head body div span table title link script textarea input".split(" ")
        KEY2: "src rel class id value type href alt".split(" ")
        KEY3: "!DOCTYPE".split(" ")

html_safe = (text) ->
    text.replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .replace(/\//g,'&#x2F;');

# its very simple and stupid
class Tokenizer

    constructor: ->
        @token_cache = {}
        @spec = specs.plain

    guess_spec: (filename) ->
        @spec = specs.plain
        ext = filename.match("\.([^\.]*)$").pop()
        for name, spec of specs
            for t in spec.FILE_TYPES
                if ext == t
                    @spec = spec
                    return

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
            out.push("<span class='#{cls}'>#{html_safe(words)}</span>")
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

        @socket.on 'open-push', (res) -> editor.open_cmd.open_push(res)
        @socket.on 'suggest-push', (res) -> editor.open_cmd.open_suggest_push(res)

        @socket.on 'error-push', (error) ->
            print "error-push", error.message


window.esc = ->
    editor.focus()

window.cd = (directory) ->
    editor.open_cmd.directory = directory


# command line diolog
class Command

    constructor: ->
        @$box = $("#command-box")
        @$input = $("#command-input")
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
        command = @$input.val()
        print "eval", command
        js = CoffeeScript.compile(command)
        eval(js)
        esc()


# goto any line diolog
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


# open file and the file autocomplete
class OpenFile

    constructor: ->
        @$box = $("#open-box")
        @$input = $("#open-input")
        @$sug = $("#open-sugest")
        @$input.keyup @keyup
        @directory = "."

    keyup: (e) =>
        key = keybord_key(e)
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
            editor.con.socket.emit "suggest",
                query: @$input.val()
                directory: @directory

    envoke: =>
        esc()
        @$box.show()
        @$input.focus()
        @$input[0].selectionStart = 0
        @$input[0].selectionEnd = @$input.val().length

    enter: ->
        esc()
        filename = @$input.val()
        editor.open(filename)

    open_push: (res) ->
        editor.filename = res.filename
        editor.tokenizer.guess_spec(res.filename)
        m = res.filename.match("\/([^\/]*)$")
        title = if m then m.pop() else res.filename
        $("title").html(title)
        window.history.pushState({}, "", "/edit/" + res.filename)
        editor.$pad.val(res.data)
        editor.update()

    open_suggest_push: (res) ->
        @$sug.children().remove()
        search = @$input.val()
        for file in res.files
            file = file.replace(search,"<b>#{search}</b>")
            @$sug.append("<div class='sug'>#{file}<div>")


# command line diolog
class SearchBox

    constructor: ->
        @$box = $("#search-box")
        @$input = $("#search-input")
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
        query = @$input.val()
        print "find", query

        at = editor.$pad[0].selectionStart
        end = editor.$pad[0].selectionEnd

        bottom = editor.text[at+1...]
        pos = bottom.indexOf(query)
        if pos != -1
            at = at + pos
        else
            pos = editor.text.indexOf(query)
            if pos != -1
                at = pos
            else
                return

        editor.$pad[0].selectionStart = at + 1
        editor.$pad[0].selectionEnd = at + query.length + 1
        editor.update()
        editor.scroll_pos(at)
        @$input.focus()


class MiniMap

    constructor: ->
        @$minimap_outer = $("#mini-map")
        @$minimap = $("#mini-map .inner")


    real_update: ->
        @$minimap.css
            height: editor.height
            width: 200
            #top: -700



# the main editor class
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
        #@$doc.keydown (e) =>
        #    @update()
        #    return @key(e)


        keydown = (e) =>
            key = keybord_key(e)
            #print "key press", key
            @con.socket.emit("keypress", key)
            if @keymap[key]?
                print @keymap[key]
                @keymap[key]()
                print "stopping prop", e
                e.stopPropagation()
                e.preventDefault()
                return null
            return true

        window.addEventListener("keydown", keydown, false)


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
        @$pad.blur =>
           @save()
        # keeps all the highlight state
        @lines = []
        @tokenizer = new Tokenizer()

        # does not update if not changed
        @old_text = ""
        @old_caret = [0,0]

        #@minimap = new MiniMap()

        @cmd = new Command()
        @goto_cmd = new GotoLine()
        @open_cmd = new OpenFile()
        @search_cmd = new SearchBox()

        @keymap =
            'esc': @focus
            'tab': @tab
            'shift-tab': @untab
            'ctrl-esc': @cmd.envoke
            'ctrl-g': @goto_cmd.envoke
            'ctrl-o': @open_cmd.envoke
            'ctrl-s': @save
            'ctrl-f': @search_cmd.envoke

            #'alt-g': => @show_promt("#goto")
            #'alt-a': => @show_promt("#command")
            #'alt-s': => @show_promt("#search")


        @focus()

        if window.location.pathname[0...5] == "/edit"
            @open(window.location.pathname[6..])

        # loop that redoes the work when needed
        @requset_update = true
        @workloop()

    open: (filename) =>
        @con.socket.emit "open"
             filename: filename
    save: =>
        @con.socket.emit "save",
            filename: @filename
            data: @$pad.val()

    focus: =>
        $("div.popup").hide()
        @$pad.focus()
        @update()

    selected_line_range: ->
        start = null
        end = null
        for line, n in @lines
            if not start and line[1] <= @old_caret[0] < line[2]
                start = n
            if not end and line[1] < @old_caret[1] <= line[2]
                end = n
        if not end or end < start
            end = start
        return [start, end]

    tab: =>
        [start, end] = @selected_line_range()
        lines = (l[3] for l in @lines)
        for n in [start..end]
            lines[n] = "    " + lines[n]
        text = (l for l in lines).join("\n")
        @set_text(text)
        @$pad[0].selectionStart = @lines[start][1]
        @$pad[0].selectionEnd = @lines[end][2] + 4 * (end-start+1)

    untab: =>
        [start, end] = @selected_line_range()
        lines = (l[3] for l in @lines)
        for n in [start..end]
            for t in [0..4]
                if lines[n][0] == " "
                    lines[n] = lines[n][1..]
        text = (l for l in lines).join("\n")
        @set_text(text)
        @$pad[0].selectionStart = @lines[start][1]
        full_length = 0
        for n in [start..end]
            full_length += lines[n].length
        @$pad[0].selectionEnd = @$pad[0].selectionStart + full_length

    set_text: (text) ->
        @$pad.val(text)
        @update()

    show_promt: (p) ->
        $(p).show()
        $(p+" input").focus()

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
        @text = text = @$pad.val() or ""

        set_line = (i, html) =>
            $("#line#{i}").html(html)
            #$("#mm#{i}").html(html) if @minimap

        add_line = (i, html) =>
            @$ghost.append("<span id='line#{i}'>#{html}</span>")
            #@minimap.$minimap.append("<span id='line#{i}'>#{html}</span>") if @minimap

        rm_line = (i) =>
            $("#line#{i}").remove()
            #$("#mm#{i}").remove() if @minimap

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
                        top = $("#line"+line[0]).position().top + 100
                        @$caret_text.html(html_safe(caret_text))
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
                        @$caret_text.html(html_safe(caret_text))
                        @$caret_line.css("top", top)
                        @$caret_char.html(html_safe(text[at..end-1]))

        @full_height = @$ghost.height()
        @$pad.height(@full_height+100)
        if performance? and performance.now?
            print "update", performance.now()-now, "ms"

        #@minimap?.real_update()

    scroll_pos: (offset) ->
        line = 0
        for c in @text[0...offset]
            if c == "\n"
                line += 1
        @scroll_line(line)

    goto_line: (line_num) ->
        line = @lines[line_num] ? @lines[@lines.length - 1]
        @$pad[0].selectionStart = line[1]
        @$pad[0].selectionEnd = line[1]
        @scroll_line(line[0])


    scroll_line: (line_num) ->
        line = @lines[line_num] ? @lines[@lines.length - 1]
        y = @get_line_y(line[0])
        y -= @$win.height()/2
        @$holder.animate(scrollTop: y)

    get_line_y: (line_num) ->
        top = $("#line"+line_num).position().top + 100
        return top

    workloop: =>
        if @requset_update
            @real_update()
            @requset_update = false
        requestAnimFrame(@workloop)

$ ->
    window.editor = new Editor()

