window.specs.flip =
    NAME: "flip"
    FILE_TYPES: ["flip"]
    CASESEN_SITIVE: true
    MULTILINE_STR: true
    DELIMITERS: " (){}[]<>+-*/%=\"~!@#&$^&|\\?;,."
    KEYWORD_PREFIX: '$'
    ESCAPECHAR: "\\"
    QUOTATION_MARK1: '"'
    QUOTATION_MARK2: '""'
    QUOTATION_MARK3: '"""'
    LINE_COMMENT: "#"
    BLOCK_COMMENT: ["###", "###"]
    PAIRS1: "()"
    PAIRS2: "[]"
    PAIRS3: "{}"
    KEY1: "' : if fn switch case then else import".split(" ")
    KEY2: "map filter reduce join split flatten".split(" ")
    KEY3: "int float list dict set".split(" ")
    KEY4: "false true NaN".split(" ")
