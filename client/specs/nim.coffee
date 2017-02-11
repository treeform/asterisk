window.specs.nim =
    NAME: "nim"
    FILE_TYPES: ["nim"]
    TAB_INDNET: 2
    CASESEN_SITIVE: false
    MULTILINE_STR: true
    DELIMITERS: " (){}[]<>+-*/%=\"'~!@#&$^&|\\?:;,."
    KEYWORD_PREFIX: '&'
    ESCAPECHAR: "\\"
    QUOTATION_MARK1: '"""'
    QUOTATION_MARK2: "'''"
    QUOTATION_MARK3: '"'
    QUOTATION_MARK4: "'"
    LINE_COMMENT: "#"
    BLOCK_COMMENT: ["#[", "]#"]
    PAIRS1: "()"
    PAIRS2: "[]"
    PAIRS3: "{}"
    KEY1: "true false nil".split(" ")
    KEY2: "echo".split(" ")
    KEY3: "
        addr and as asm atomic
        bind block break
        case cast concept const continue converter
        defer discard distinct destroy div do
        elif else end enum except export
        finally for from func
        generic
        if import in include interface is isnot iterator
        let
        macro method mixin mod
        nil not notin
        object of or out
        proc ptr
        raise ref return
        shl shr static
        template try tuple type
        using
        var
        when while with without
        xor
        yield".split(" ")
    KEY4: "foo".split(" ")
