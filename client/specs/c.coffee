window.specs.c =
    NAME: "C"
    FILE_TYPES: ["c", "h", "cpp", "c++", "cxx"]
    CASESEN_SITIVE: true
    MULTILINE_STR: true
    DELIMITERS: " (){}[]<>+-*/%=\"'~!@#&$^&|\\?:;,."
    KEYWORD_PREFIX: '_'
    ESCAPECHAR: "\\"
    QUOTATION_MARK1: '`'
    QUOTATION_MARK2: "'"
    QUOTATION_MARK3: '"'
    LINE_COMMENT: "//"
    BLOCK_COMMENT: ["/*", "*/"]
    PAIRS1: "()"
    PAIRS2: "[]"
    PAIRS3: "{}"
    KEY1: "break case continue do else for if return switch while with".split(" ")
    KEY2: "static inline float int double long char short struct void typedef const".split(" ")
    KEY3: "#include #define #endif #ifndef".split(" ")
    KEY4: "null true false".split(" ")
