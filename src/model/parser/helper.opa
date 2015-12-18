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