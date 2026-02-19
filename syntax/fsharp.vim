vim9script

# Prevent double loading
if exists("b:current_syntax")
  finish
endif

# ==========================================
# 1. Keywords (Basic)
# ==========================================

# Boolean & Null
syntax keyword fsharpBoolean true false
syntax keyword fsharpNull    null

# Conditionals
syntax keyword fsharpConditional if then else elif match when

# Loops
syntax keyword fsharpRepeat for to downto while do done

# Exceptions & Assertions
syntax keyword fsharpException try with finally exception assert

# Types
syntax keyword fsharpType type class struct interface delegate val void

# Access & Modifiers
syntax keyword fsharpModifier abstract default extern inline internal override private public static mutable

# Modules & Namespaces
syntax keyword fsharpStructure module namespace open global

# Core Keywords
syntax keyword fsharpKeyword and as base begin downcast end fixed fun function
syntax keyword fsharpKeyword in inherit lazy let member new not of or rec
syntax keyword fsharpKeyword return select upcast use yield

# Computation Expressions (let!, use!)
syntax match fsharpKeyword "\<\(let\|use\|do\|yield\|return\|match\|and\)\!"

# OCaml Compatibility
syntax keyword fsharpReserved asr land lor lsl lsr lxor mod sig

# Reserved for Future
syntax keyword fsharpReserved break checked component const constraint continue event
syntax keyword fsharpReserved external include mixin parallel process protected pure
syntax keyword fsharpReserved sealed tailcall trait virtual


# ==========================================
# 2. Operators
# ==========================================

# Match operator sequences like |>, ->, +, /
syntax match fsharpOperator "[-!%&+*/<>=@^|~?]\+"

# Special symbols
syntax match fsharpOperator "::"
syntax match fsharpOperator "\.\."
syntax match fsharpOperator "_"


# ==========================================
# 3. Strings & Comments (High Priority)
# ==========================================

# Single-line comment (// ...)
syntax match fsharpComment "\/\/.*$"

# Block comment (* ... *)
syntax region fsharpBlockComment start="(\*" end="\*)" contains=fsharpBlockComment

# Regular string ("...")
syntax region fsharpString start='"' skip='\\\\\|\\"' end='"'

# Verbatim string (@"...")
syntax region fsharpVerbatimString start='@"' end='"' skip='""'

# Triple-quoted string ("""...""")
syntax region fsharpTripleString start='"""' end='"""'


# ==========================================
# 4. Highlight Group Links
# ==========================================

highlight default link fsharpComment        Comment
highlight default link fsharpBlockComment   Comment
highlight default link fsharpString         String
highlight default link fsharpVerbatimString String
highlight default link fsharpTripleString   String

highlight default link fsharpBoolean     Boolean
highlight default link fsharpNull        Constant
highlight default link fsharpConditional Conditional
highlight default link fsharpRepeat      Repeat
highlight default link fsharpException   Exception
highlight default link fsharpType        Type
highlight default link fsharpModifier    StorageClass
highlight default link fsharpStructure   Structure
highlight default link fsharpKeyword     Keyword
highlight default link fsharpReserved    Special

highlight default link fsharpOperator    Statement

b:current_syntax = "fsharp"
