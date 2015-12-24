/**
 * a list of parser helper methods.
 */
module Util {
  // TODO write some real text functions with escape!

  function attr(string a){
    parser {
      case "{a}=\"" x = ((!["\""] .)*) "\"": Text.to_string(x);
    }
  }

  parse = Parser.parse;
  try = Parser.try_parse;

  parameters = parser {
    case "<run><parameters>" p=((!["<"] .)*) "</parameters><result>":
      Text.to_string(p);
  }

  file_parser = parser {
    case "<file " name = attr("name") " " path = attr("path") ">":
      {name: name, path: path, fkt: Map.empty}
  }

  fkt_parser = parser {
    case "<function " name = attr("name") ">":
      {name: name, nodes: []}
  }

  node_parser = parser {
    case "<node " name = attr("name") "/>":
      name
  }

  call_parser = parser {
    case "<call " id=attr("id") " " file=attr("file") " line=\""
      line=Rule.natural "\" order=\""  order=Rule.natural "\">":
        {~id, ~file, ~line, ~order, context: Map.empty, path: Map.empty};
  }

  context_parser = parser {
    case "<context>": void
  }

  analysis_parser = parser {
    case "<analysis " name=attr("name") ">": name
  }

  value_parser = parser {
    case "<value>": void
  }

  inner_value = parser {
    case "<map>": {map}
    case "<set>": {set}
    case "<data>": {data}
  }

  function start_tag(string tag){
    parser {
      case "<{tag}" (![">"] .)* ">": void
    }
  }
  function close_tag(string tag){
    parser {
      case "</{tag}>": void
    }
  }
}