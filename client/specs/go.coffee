window.specs.go =
    NAME: "go"
    FILE_TYPES: ["go"]
    CASESEN_SITIVE: true
    MULTILINE_STR: true
    DELIMITERS: " (){}[]<>+*/%=\"'~!@#&$^&|\\?:;,."
    KEYWORD_PREFIX: '&'
    ESCAPECHAR: "\\"
    QUOTATION_MARK1: "\""
    QUOTATION_MARK2: "\'"
    QUOTATION_MARK3: "\`"
    LINE_COMMENT: "//"
    BLOCK_COMMENT: ["/*", "*/"]
    PAIRS1: "()"
    PAIRS2: "[]"
    PAIRS3: "{}"
    KEY1: [
        "break", "default", "func", "interface", "select",
        "case", "defer", "go", "map", "struct",
        "chan", "else", "goto", "package", "switch",
        "const", "fallthrough", "if", "range", "type",
        "continue", "for", "import", "return", "var"
    ]
    KEY2: [
        "uint8", "uint16", "uint32", "uint64", "int8", "int16",
        "int32", "int64", "float32", "float64", "complex64",
        "complex128", "byte", "rune",
        "string", "int"
    ]
    KEY3: [
        "true", "false", "iota", "nil",
        "append", "cap", "close", "complex", "copy", "delete", "imag", "len",
        "make", "new", "panic", "print", "println", "real", "recover"
    ]
