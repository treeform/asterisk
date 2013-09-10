window.specs.coffee =
    NAME: "CoffeeScript"
    FILE_TYPES: ["coffee"]
    CASESEN_SITIVE: true
    MULTILINE_STR: true
    DELIMITERS: " (){}[]<>+-*/%=\"'~!@#&$^&|\\?:;,."
    KEYWORD_PREFIX: '&'
    ESCAPECHAR: "\\"
    QUOTATION_MARK1: "\""
    QUOTATION_MARK2: "\'"
    QUOTATION_MARK3: "`"
    LINE_COMMENT: "#"
    PAIRS1: "()"
    PAIRS2: "[]"
    PAIRS3: "{}"
    KEY1: "break continue else for if return while and not or in".split(" ")
    KEY2: "class -> => extends new".split(" ")
    KEY3: "catch finally throw try".split(" ")
