module Bpl
  IDENTIFIER = /[a-zA-Z_.$\#'`~^\\?][\w.$\#'`~^\\?]*/
end

class BoogieLanguage
macro
  BLANK     \s+
  MLC_OPEN    \/\*
  MLC_CLOSE   \*\/
  SLC         \/\/
  IDENT     [a-zA-Z_.$\#'`~^\\?][\w.$\#'`~^\\?]*
  OPERATOR  <==>|==>|\|\||&&|==|!=|<:|<=|<|>=|>|\+\+|\+|-|\*|\/|{:|:=|::|:|\|
  KEYWORD   \b(assert|assume|axiom|bool|break|bv(\d+)|call|complete|const|else|ensures|exists|false|finite|forall|free|function|goto|havoc|if|implementation|int|invariant|modifies|old|procedure|requires|return|returns|then|true|type|unique|var|where|while)\b
  
rule

          {MLC_OPEN}((?!{MLC_CLOSE})(.|\n))*{MLC_CLOSE}
          {SLC}.*(?=\n)

          \"[^"]*\"         { [:STRING, text[1..-2]]}

          {BLANK}

          {OPERATOR}        { [text, text] }

          \d+bv\d+          { [:BITVECTOR, {value: text[/(\d+)bv/,1].to_i, base: text[/bv(\d+)/,1].to_i}] }
          \d+               { [:NUMBER, text.to_i] }
          bv\d+\b           { [:BVTYPE, text[2..-1].to_i] }

          {KEYWORD}         { [text, text] }

          {IDENT}           { [:IDENTIFIER, text] }
          .                 { [text, text] }

end
