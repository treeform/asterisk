requestAnimFrame = window.requestAnimationFrame or 
        window.webkitRequestAnimationFrame or
        window.mozRequestAnimationFrame or
        window.oRequestAnimationFrame  or
        (-> (cb) window.setTimeout(cb, 1000 / 60))

print = (args...) -> console.log(args...)

CARET = "<span id='caret' class='caret-at'>&#x2588;</span>"
SEL_START = "<span class='selection'>"
SEL_END = "</span>"
    


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
        
    tokenize_line: (@line) ->
        spec = specs.python
        colored = []
        norm = 0
        old_c = " "
        for c, i in line
            if c == @spec.QUOTATION_MARK1
                n = 1
                while c != line[i+n] and i+n < line.length 
                    if line[i+n] == @spec.ESCAPECHAR
                        n+=1
                    n+=1
                colored.push(["string",line[i..i+n]])
                i += n
                #i = line.length
                continue
        
            if c == @spec.LINE_COMMENT
                colored.push(["comment",line[i..]])
                i = line.length
                continue
            if old_c in @spec.DELIMITERS
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
            
        #print line, colors.join "|"
        out = []
        for [cls, words] in colored
            out.push("<span class='#{cls}'>#{words}</span>")
        out.push("\n")
        
        return [colored, out.join("")]
        
    keywords: (c, i, line, colored, spec) ->
        #print c, i, line
        for k in [0..6]
            if spec["KEY"+k]?
                for t in spec["KEY"+k]
                    if c == t[0]
                        w = line[i..i+t.length-1]
                        last = line[i+t.length]
                        #print "last [#{last}]"
                        if not last?
                            last = " "
                        if w == t and last in spec.DELIMITERS
                            colored.push(["key"+k, w])
                            i += t.length
                            return i-1
        return
    
class Editor

    constructor: ->

        @$doc = $(document) 
        @$win = $(window)
        @$holder = $(".holder")
        @$pad = $(".pad")
        @$ghost = $(".ghost")
        @$highlight = $(".highlight")

        @$caret_line = $("#caret-line")
        @$caret_text = $("#caret-text")
        @$caret_char = $("#caret-char")
        
        @requset_update = true

        @old_text = ""
        @old_caret = [0,0]
       
        @$doc.keypress(@update)
        @$doc.keyup(@update)
        @$doc.keydown(@update)
        
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
          
        @workloop()
        
      
        
        
    update: =>
       
        @requset_update = true

   

    real_update: ->
        now = performance.now()
        
        h = @$win.height()
        w = @$win.width()
        @$holder.height(h)
        @$holder.width(w)
        @$pad.width(w)
        @$ghost.width(w)
        @$highlight.width(w)
        
        text = @$pad.val()
        
        # high light
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
                
            
            #print @lines
             
            # highlight 
            #v = v.replace(/a/g, '<span class="mark">a</span>')
            # new lines 
            #v = v.replace(/\s/g, '&sp;')
            #v = v.replace(/\n/g, '<br/>')
            
            
            

    
        # caret 
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
                                
                
                    #caret_text = text[line[1]..start-1] + SEL_START + text[start..end] + SEL_END
            
        ###
        if @old_caret != [at, end]
            @old_caret = [at, end]
            if end != at
                start = at
                if start > end
                    [start,end] = [end,start]
                start -= 1
                end -= 1
                caret_text = text[..start-1] + SEL_START + text[start..end] + SEL_END
            else
                caret_text = text[..at-1] + CARET
            #print caret_text
            @$highlight.html(caret_text)
        ###    
        
        h = @$ghost.height()
        @$pad.height(h+100)
        #@$highlight.height(h)
            
        print "update", performance.now()-now, "ms"
        
 

    workloop: =>
        if @requset_update
            @real_update() 
            @requset_update = false
        requestAnimFrame(@workloop)
    
$ new Editor()
