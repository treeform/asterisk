window.specs.python =
    NAME: "python"
    FILE_TYPES: ["py", "pyw"]
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
    KEY1: "break continue elif else for if pass return while and not or in del".split(" ")
    KEY2: "class def import from lambda except finally raise try yield".split(" ")
    KEY3: "abs divmod input open staticmethod
        all enumerate int ord str
        any eval isinstance pow sum
        basestring execfile issubclass print super
        bin file iter property tuple
        bool filter len range type
        bytearray float list raw_input unichr
        callable format locals reduce unicode
        chr frozenset long reload vars
        classmethod getattr map repr xrange cmp
        globals max reversed zip compile hasattr
        memoryview round __import__ complex hash
        min set apply delattr help next setattr
        buffer dict hex object slice coerce dir
        id oct sorted intern".match(/[^ \n]+/g)
