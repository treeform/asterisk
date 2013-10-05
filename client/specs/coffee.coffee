window.specs.coffee =
    NAME: "CoffeeScript"
    FILE_TYPES: ["coffee"]
    CASESEN_SITIVE: true
    MULTILINE_STR: true
    DELIMITERS: " (){}[]<>+-*/%=\"'~!@#&$^&|\\?:;,."
    KEYWORD_PREFIX: '&'
    ESCAPECHAR: "\\"
    QUOTATION_MARK1: '"""'
    QUOTATION_MARK2: "'"
    QUOTATION_MARK3: '"'
    LINE_COMMENT: "#"
    BLOCK_COMMENT: ["###", "###"]
    PAIRS1: "()"
    PAIRS2: "[]"
    PAIRS3: "{}"
    KEY1: "break continue else for if then when return while and not or in of until do".split(" ")
    KEY2: "class -> => extends new delete".split(" ")
    KEY3: "catch finally throw try".split(" ")
    KEY4: "undefined true false on yes off no".split(" ")
