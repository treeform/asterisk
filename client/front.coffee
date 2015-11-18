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
    8: "backspace"
    9: "tab"
    13: "enter"
    27: "esc"
    32: "space"
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

common_str = (strs) ->
    return "" if strs.length == 0
    return strs[0] if strs.length == 1
    first = strs[0]
    common = ""
    fail = false
    for c,i in first
        for str in strs
            if str[i] != c
                fail = true
                break
        break if fail
        common += c
    return common


gcd = (a, b) ->
    while b
        [a, b] = [b, a % b]
    return a

guess_indent = (text) ->
    indents = {}
    for line in text.split("\n")
        indent = line.match(/^\s*/)[0].length
        continue if indent == 0
        if indent of indents
            indents[indent] += 1
        else
            indents[indent] = 1
    indents = ([k*1,v] for k,v of indents)
    indents = indents.sort (a,b) -> b[1] - a[1]
    indents = (i[0] for i in indents)
    if indents.length == 1
        return indents[0]
    if indents.length == 0
        return 4
    indent = gcd(indents[0], indents[1])
    return indent

window.specs =
    # plain spec highlights strings and quotes and thats it
    plain:
        NAME: "plain"
        FILE_TYPES: []
        CASESEN_SITIVE: true
        MULTILINE_STR: true
        DELIMITERS: " (){}[]<>+-*/%=\"'~!@#&$^&|\\?:;,."
        ESCAPECHAR: "\\"
        QUOTATION_MARK1: "\""
        BLOCK_COMMENT: ["",""]
        PAIRS1: "()"
        PAIRS2: "[]"
        PAIRS3: "{}"
        KEY1: []
        KEY2: []
        KEY3: []


html_safe = (text) ->
    text.replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;') #"
        .replace(/'/g, '&#x27;') #'
        .replace(/\//g,'&#x2F;');

# its very simple and stupid
class Tokenizer

    constructor: ->
        @token_cache = {}
        @spec = specs.plain

    guess_spec: (filename) ->
        @spec = specs.plain
        m = filename.match("\.([^\.]*)$")
        if not m
            ext = "txt"
        else
            ext = m.pop()
        for name, spec of specs
            for t in spec.FILE_TYPES
                console.log t, name, specs
                if ext == t
                    @spec = spec
                    @token_cache = {}
                    return

    tokenize: (@line, @mode) ->
        key = @mode + "|" + @line
        if @token_cache[key]
            return @token_cache[key]
        return @token_cache[key] = @tokenize_line()

    colorize_line: ->


        line = @line
        spec = @spec
        colored = []
        norm = 0

        i = 0

        mode = in_mode = @mode[1]

        next_char = ->
            c = line[i]
            i += 1
            return c

        prev_char = ->
            return line[i-1] or " "

        match = (str) ->
            if not str
                return
            substr = line[i...i + str.length]
            if substr == str
                i += str.length
                return substr
            else
                return false

        keywords =  ->
            for k in [0..6]
                if spec["KEY"+k]?
                    for key_word in spec["KEY"+k]
                        text = line[i...i + key_word.length]
                        end = line[i+key_word.length]
                        if text == key_word and (end in spec.DELIMITERS or not end)
                            add_str("key"+k, match(key_word))
                            return true
            return false

        add_str = (mode, str) ->
            if not str
                return
            last = colored[colored.length-1]
            if not last or last[0] != mode
                colored.push([mode, str])
            else
                last[1] += str


        while i < line.length

            switch mode
                when "plain"
                    if c = match(spec.ESCAPECHAR)
                        add_str(mode, c)
                        add_str(mode, next_char())
                    else if c = match(spec.QUOTATION_MARK1) or
                      c = match(spec.QUOTATION_MARK2) or
                      c = match(spec.QUOTATION_MARK3) or
                      c = match(spec.QUOTATION_MARK4)
                        mode = c
                        add_str("string", c)

                    else if spec.BLOCK_COMMENT and c = match(spec.BLOCK_COMMENT[0])
                        add_str("comment", c)
                        mode = "block_comment"

                    else if c = match(spec.LINE_COMMENT)
                        add_str("comment", line[(i-spec.LINE_COMMENT.length)...])
                        i = line.length

                    else if prev_char() in spec.DELIMITERS
                        if not keywords()
                            add_str("text", next_char())
                    else
                        add_str("text", next_char())

                when spec.QUOTATION_MARK1, spec.QUOTATION_MARK2, spec.QUOTATION_MARK3, spec.QUOTATION_MARK4
                    if c = match(spec.ESCAPECHAR)
                        add_str("string", c)
                        add_str("string", next_char())
                    else if c = match(mode)
                        add_str("string", c)
                        mode = "plain"
                    else
                        add_str("string", next_char())
                when "block_comment"
                    if c = match(spec.ESCAPECHAR)
                        add_str("comment", c)
                        add_str("comment", next_char())
                    else if c = match(spec.BLOCK_COMMENT[1])
                        add_str("comment", c)
                        mode = "plain"
                    else
                        add_str("comment", next_char())

        #console.log JSON.stringify(colored)
        return [colored, [in_mode, mode]]

    tokenize_line: ->
        [colored, mode] = @colorize_line()
        out = []

        for [cls, words] in colored
            out.push("<span class='#{cls}'>#{html_safe(words)}</span>")
            #for c in words
            #    out.push("<span class='#{cls}'>#{html_safe(w)}</span>")
        #out.push(@line)
        out.push("\n")
        #print "line", [colored, mode, out.join("")]
        return [colored, mode, out.join("")]




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
            editor.goto_line(line - 1)


# open file and the file autocomplete
class OpenFile

    constructor: ->
        @$box = $("#open-box")
        @$input = $("#open-input")
        @$sug = $("#open-sugest")
        @$input.keyup @keyup
        @directory = localStorage.getItem("directory") or "."
        @$sug.on "click", ".sug", (e) ->
            filename = $(e.currentTarget).text()
            esc()
            editor.open(filename)

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
            editor.con.ws.safeSend "suggest",
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
        editor.opened(res.filename, res.data)
        @add_common(res.filename)

    open_suggest_push: (res) ->
        @$sug.children().remove()
        search = @$input.val()
        for file in res.files
            file = file.replace(search,"<b>#{search}</b>")
            @$sug.append("<div class='sug'>#{file}<div>")
        # add in common files
        for file in @get_common()
            if file.indexOf(search) != -1
                file = file.replace(search,"<b>#{search}</b>")
                @$sug.append("<div class='sug sug-common'>#{file}<div>")

    add_common: (file) ->
        common = @get_common()
        for f, n in common
            if f == file
                common.splice(n,1)
                break
        common.unshift(file)
        common = common[..10]
        common = localStorage.setItem("common", JSON.stringify(common))

    get_common: ->
        common = localStorage.getItem("common")
        if common?
            return JSON.parse(common)
        return []

# command line diolog
class SearchBox

    constructor: ->
        @$box = $("#search-box")
        @$search = $("#search-input")
        @$search.keyup (e) =>
            if keybord_key(e) == "enter"
                @search()
            else if keybord_key(e) == "down"
                @search()
            else if keybord_key(e) == "up"
                @search(false)
            @$search.focus()

        @$replace = $("#replace-input")
        @$replace.keyup (e) =>
            if keybord_key(e) == "enter"
                @replace()
                @search()
            else if keybord_key(e) == "down"
                @search()
            else if keybord_key(e) == "up"
                @search(false)
            @$replace.focus()

    envoke: =>
        esc()
        @$box.show()
        @$search.focus()
        @$search[0].selectionStart = 0
        @$search[0].selectionEnd = @$search.val().length

    search: (down=true)->
        query = @$search.val()
        [text, [at, end], scroll] = editor.get_text_state()
        if down
            bottom = text[at+1...]
            pos = bottom.indexOf(query)
            if pos != -1
                at = at + pos + 1
            else
                pos = text.indexOf(query)
                if pos != -1
                    at = pos
                else
                    return
        else
            top = text[...at]
            pos = top.lastIndexOf(query)
            if pos != -1
                at = pos
            else
                pos = text.lastIndexOf(query)
                if pos != -1
                    at = pos
                else
                    return

        editor.$pad[0].selectionStart = at
        editor.$pad[0].selectionEnd = at + query.length
        editor.update()
        editor.scroll_pos(at)

    replace: ->
        [text, [start, end], scroll] = editor.get_text_state()
        query = @$search.val()
        if text[start...end] == query
            replace = @$replace.val()
            text = text[...start] + replace + text[end...]
            editor.set_text_state([text, [start, start + replace.length], scroll])


class UndoStack

    constructor: ->
        @clear()

    clear: =>
        @undos = []
        @redos = []

    undo: =>
        if @undos.length > 0
            text = @undos.pop()
            # dont allow to pop 1st undo
            if @undos.length == 0
                @undos.push(text)
            @redos.push(editor.get_text_state())
            editor.set_text_state(text)

    redo: =>
        if @redos.length > 1
            text = @redos.pop()
            @undos.push(editor.get_text_state())
            editor.set_text_state(text)

    snapshot: =>
        text = editor.get_text_state()
        old_text = @undos[@undos.length-1]
        @redos = []
        if !old_text? or old_text[0] != text[0]
            @undos.push(text)


window.logout = ->
    localStorage.setItem("username", "")
    localStorage.setItem("password", "")
    location.reload()

class Auth

    constructor: ->

        @$login_box = $("#login-box")
        @$login_button = $("#login-button")
        @$login_username = $("#login-username")
        @$login_password = $("#login-password")

        @$login_username.val(localStorage.getItem("username"))
        @$login_password.val(localStorage.getItem("password"))

        @$login_button.click =>
            @login()
            return false

    think: ->
        if @$login_username.val()
            @login()
        else
            @show()

    login: ->
        username = @$login_username.val()
        password = @$login_password.val()
        localStorage.setItem("username", username)
        localStorage.setItem("password", password)
        # send auth info
        editor.con.ws.safeSend "auth",
            username: username
            password: password

    show: ->
        @$login_box.show()

    loggedin: ->
        @$login_box.hide()
        if editor.fresh and window.location.pathname[0...5] == "/edit"
            editor.open(window.location.pathname[6..])
        esc()

class Connection

    constructor: ->
        host = window.document.location.host.replace(/:.*/, '')
        @ws = new WebSocket 'ws://' + location.hostname + ":" + 21977

        @ws.safeSend = (msg, kargs) =>
            console.log "sending", msg, kargs
            @ws.send JSON.stringify
                msg: msg
                kargs: kargs


        @ws.onopen = (data) ->
            console.log("connected with", data.iden)
            editor.auth.think()

        @ws.onmessage = (e) ->
            packet = JSON.parse(e.data)
            msg = packet.msg
            kargs = packet.kargs
            console.log "got message", msg, kargs
            switch msg
                when 'open-push'
                    editor.open_cmd.open_push(kargs)
                when 'loggedin'
                    editor.auth.loggedin(kargs)
                when 'suggest-push'
                    editor.open_cmd.open_suggest_push(kargs)
                when 'error-push'
                    if kargs.message == "invalid username or password"
                        editor.auth.show()
                    if kargs.message == "not logged in"
                        editor.auth.login()
                    editor.$errorbox.show()
                    editor.$errorbox.html(kargs.message)

                when 'marks-push'
                    editor.add_marks(kargs)


        ###
        , (res) ->
        @ws.on 'loggedin', (res) ->
        @ws.on 'error-push', (error) ->
            if error.message == "invalid username or password"
                editor.auth.show()
            if error.message == "not logged in"
                editor.auth.login()
            editor.$errorbox.show()
            editor.$errorbox.html(error.message)

        @ws.on 'marks-push', (marks) ->
        ###

window.esc = ->
    editor.$errorbox.hide()
    editor.focus()


window.cd = (directory) ->
    editor.open_cmd.directory = directory
    localStorage.setItem("directory", directory)


# the main editor class
class Editor

    # create a new editor
    constructor: ->
        @fresh = true
        window.editor = @
        @con = new Connection()
        @filename = "untiled"
        @tab_width = 4

        # grab common elements
        @$doc = $(document)
        @$win = $(window)
        @$holder = $(".holder")
        @$marks = $(".marks")
        @$pad = $(".pad")
        @$ghost = $(".ghost")
        @$highlight = $(".highlight")
        @$errorbox = $("#error-box")
        @$errorbox.hide()
        # grab careat
        @$caret_line = $("#caret-line")
        @$caret_text = $("#caret-text")
        @$caret_char = $("#caret-char")
        @$caret_tail = $("#caret-tail")

        @auth = new Auth()

        keydown = (e) =>
            @update()
            key = keybord_key(e)
            if key.length != 1 and key.indexOf("-") == -1
                # for all non character keys non meta
                @undo.snapshot()
            @con.ws.safeSend("keypress", key)
            if @keymap[key]?
                @keymap[key]()
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
            @undo.snapshot()
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

        @$doc.on "mouseenter", ".mark", (e) ->
            $(".mark-text").hide()
            $(e.target).find(".mark-text").show()


        # keeps all the highlight state
        @lines = []
        @tokenizer = new Tokenizer()

        # does not update if not changed
        @old_text = ""
        @old_caret = [0,0]

        @cmd = new Command()
        @goto_cmd = new GotoLine()
        @open_cmd = new OpenFile()
        @search_cmd = new SearchBox()
        @undo = new UndoStack()

        @keymap =
            'esc': esc
            'tab': @tab
            'shift-tab': @deindent
            'ctrl-esc': @cmd.envoke
            'ctrl-i': @cmd.envoke
            'ctrl-g': @goto_cmd.envoke
            'ctrl-o': @open_cmd.envoke
            'ctrl-l': @open_cmd.envoke
            'ctrl-s': @save
            'ctrl-f': @search_cmd.envoke
            'ctrl-z': @undo.undo
            'ctrl-shift-z': @undo.redo

        @focus()

        # loop that redoes the work when needed
        @requset_update = true
        @workloop()

    # open current file
    open: (filename) =>
        @con.ws.safeSend "open",
             filename: filename

    # opened
    opened: (filename, textdata) ->

        @fresh = false
        if @filename != filename
            @undo.clear()

        @filename = filename
        @tokenizer.guess_spec(filename)
        m = filename.match("\/([^\/]*)$")
        title = if m then m.pop() else filename
        $("title").html(title)
        window.history.pushState({}, "", "/edit/" + filename)
        @$pad.val(textdata)
        @undo.snapshot()
        @clear_makrs()
        @update()




    # save current file
    save: =>
        text = @$pad.val()
        # replace tabs by spaces
        space = (" " for _ in [0...@tab_width]).join("")
        text = text.replace(/\t/g, space)
        # strip trailing white space onlines
        text = text.replace(/[ \r]*\n/g,"\n").replace(/\s*$/, "\n")
        @con.ws.safeSend "save",
            filename: @filename
            data: text

    # focus the pad
    focus: =>
        $("div.popup").hide()
        @$pad.focus()
        @update()

    # return the lines selected
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

    # tab was pressed, complex behavior
    tab: =>
        if $("#search-input").is(":focus")
            $("#replace-input").focus()
            return
        if $("#replace-input").is(":focus")
            $("#search-input").focus()
            return
        if not @$pad.is(":focus")
            return
        if @autocomplete()
            return
        @indent()
        return

    # auto complete right at the current cursor
    autocomplete: =>
        [text, [start, end], s] = @get_text_state()
        # if some thing is selected don't auto complete
        if start != end
            return false
        string = text.substr(0, start)
        at = text[start]
        string = string.match(/\w+$/)
        # only when at char is splace and there is a string under curser
        if (not at or at.match(/\s/)) and string
            options = {}
            words = text.split(/\W+/).sort()
            if words
                for word in words
                    word_match = word.match("^" + string + "(.+)")
                    if word_match and word_match[1] != ""
                        options[word_match[1]] = true
                add = common_str(k for k of options)
                if add.length > 0
                    @insert_text(add)
            return true
        return false

    # insert text into the selected range
    insert_text: (add) =>
        [text, [start, end], s] = @get_text_state()
        text = text[..start-1] + add + text[end..]
        start += add.length
        end += add.length
        @set_text_state([text, [start, end], s])

    # indent selected range
    indent: =>
        [start, end] = @selected_line_range()
        if start == end
           real = @$pad[0].selectionStart
           just_tab = true

        lines = (l[3] for l in @lines)
        for n in [start..end]
            lines[n] = "    " + lines[n]
        text = (l for l in lines).join("\n")
        @set_text(text)

        if just_tab
            @$pad[0].selectionStart = real + @tab_width
            @$pad[0].selectionEnd = @$pad[0].selectionStart
        else
            @$pad[0].selectionStart = @lines[start][1]
            @$pad[0].selectionEnd = @lines[end][2] + @tab_width * (end-start+1)

    # deindent selected range
    deindent: =>
        [start, end] = @selected_line_range()
        if start == end
           real = @$pad[0].selectionStart
           just_tab = true

        lines = (l[3] for l in @lines)
        old_length = 0
        for n in [start..end]
            old_length += lines[n].length + 1
            for t in [0...@tab_width]
                if lines[n][0] == " "
                    lines[n] = lines[n][1..]
        text = (l for l in lines).join("\n")
        @set_text(text)

        new_length = 0
        for n in [start..end]
            new_length += lines[n].length + 1
        if just_tab
            if real - @tab_width > @lines[start][1]
                @$pad[0].selectionStart = real - @tab_width
            else
                @$pad[0].selectionStart = @lines[start][1]
            @$pad[0].selectionEnd = @$pad[0].selectionStart
        else
            @$pad[0].selectionStart = @lines[start][1]
            @$pad[0].selectionEnd = @$pad[0].selectionStart + new_length

    # set the text of the pad to a value
    set_text: (text) ->
        @$pad.val(text)
        @update()

    # return the text of the pad
    get_text: () ->
        return @$pad.val()

    # set the state of the text
    set_text_state: (text_state) ->
        @$pad.val(text_state[0])
        @$pad[0].selectionEnd = text_state[1][0]
        @$pad[0].selectionStart = text_state[1][1]
        @$holder.stop(true).animate(scrollTop: text_state[2])
        @update()

    # gets the state of the text
    get_text_state: () ->
        start = @$pad[0].selectionStart
        end = @$pad[0].selectionEnd
        if start > end
            [start, end] = [end, start]
        text_state = [
            @$pad.val(),
            [start, end],
            @$holder.scrollTop(),
        ]
        return text_state

    # request for an update to be made
    update: =>
        @requset_update = true

    # redraw the ghost buffer
    real_update: ->
        if performance? and performance.now?
            now = performance.now()

        # adjust hight and width of things
        @height = @$win.height()
        @width = @$win.width() - 10  # 10 for scrollbar
        @$holder.height(@height)
        a = 4
        @$holder.width(@width)
        @$pad.width(@width-a)
        @$ghost.width(@width-a)
        @$highlight.width(@width-a)
        @$caret_line.width(@width-a)
        @$marks.width(@width-a)


        # get the current text
        @text = text = @$pad.val() or ""

        set_line = (i, html) =>
            $("#line#{i}").html(html)
            # for debugging refresh performance
            #$("#line#{i}").stop().css("opacity", 0)
            #$("#line#{i}").animate({opacity: 1}, 300);

        add_line = (i, html) =>
            @$ghost.append("<span id='line#{i}'>#{html}</span>")

        rm_line = (i) =>
            $("#line#{i}").remove()

        # high light if it has changed
        if @old_text != text
            @old_text = text
            lines = text.split("\n")
            start = 0
            for line, i in lines
                if i > 0
                    prev_mode = @lines[i-1][4]
                else
                    prev_mode = ["plain", "plain"]

                end = start + line.length + 1
                if @lines[i]?
                    oldline = @lines[i]
                    oldline[1] = start
                    oldline[2] = end
                    #console.log [oldline[3], "!=", line, "or", oldline[4], "!=", prev_mode]
                    if oldline[3] != line or prev_mode[1] != oldline[4][0]
                    #iif oldline[3] != line or oldline[4] != prev_mode
                        #console.log "true"
                        [colored, mode, html] = @tokenizer.tokenize(line, prev_mode)
                        oldline[3] = line
                        oldline[4] = mode
                        set_line(i, html)
                else
                    [colored, mode, html] = @tokenizer.tokenize(line, prev_mode)
                    @lines.push([i, start, end, line, mode])
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

                        @$caret_tail.html(html_safe(text[at+1...text.indexOf("\n", at)]))

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
                        @$caret_tail.html(html_safe(text[end..text.indexOf("\n", end)]))

        @full_height = @$ghost.height()
        @$pad.height(@full_height+100)

    # scroll to a char position
    scroll_pos: (offset) ->
        line = 0
        for c in @text[0...offset]
            if c == "\n"
                line += 1
        @scroll_line(line)

    # go to a line number
    goto_line: (line_num) ->
        line = @lines[line_num] ? @lines[@lines.length - 1]
        @$pad[0].selectionStart = line[1]
        @$pad[0].selectionEnd = line[1]
        @scroll_line(line[0])

    # animate a scroll to a line number
    scroll_line: (line_num) ->
        line = @lines[line_num] ? @lines[@lines.length - 1]
        y = @get_line_y(line[0])
        y -= @$win.height()/2
        @$holder.stop(true).animate(scrollTop: y)

    # get line's y cordiante for scrolling
    get_line_y: (line_num) ->
        top = $("#line"+line_num).position().top + 100
        return top

    # adds the makrs about lint stuff to the editor
    # this is used to show errors or git lines
    add_marks: (marks) ->
        if marks.filename == @filename
            $layer = $("#marks-"+marks.layer)
            console.log "adding marks", marks, $layer
            $layer.html("")
            for mark in marks.marks
                continue if not mark
                console.log "add mark on ", mark.line
                $line = $("#line"+(mark.line-1))
                p = $line.position()
                return if not p
                if mark.tag == "change"
                    $layer.append("<div class='mark change' style='top:#{p.top}px;'>*</div>")
                else
                    $layer.append("<div class='mark' style='top:#{p.top}px;'>#{mark.tag}:#{mark.text}</div>")


    clear_makrs: (layer) ->
        $(".marks").html("")

    # loop that does the work for rendering when update is requested
    workloop: =>
        if @requset_update
            @real_update()
            @requset_update = false
        requestAnimFrame(@workloop)

$ ->
    window.editor = new Editor()
