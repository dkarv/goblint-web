module GraphParser {
  // parser for dot syntax. produces a graph
  function parse_graph(str){
    Parser.try_parse( graph_parser,str);
  }

  private function string decode_html(string str){
    entity = parser {
      case "quot": "\""
      case "amp": "&"
      case "apos": "\'"
      case "lt": "<"
      case "gt": ">"
    }
    escape = parser {
      case "&" e=entity ";": e
      case "&": "&"
    }
    elem = parser {
      case a=((!["&"] .)*) b=escape: Text.to_string(a) ^ b
    }
    p = parser {
      x=elem* z=((!["&"] .)*):
        List.fold(function(y, acc){
          acc ^ y;
        },x, "") ^ Text.to_string(z);
    }
    Parser.parse(p, str);
  }

  name = parser {
    case name=(([a-zA-Z0-9])*): Text.to_string(name)
  }
  // matches all whitespace, newline, tabs
  ws = parser {
    case (" "|"\n"|"\r"|"\t")
  }

  label = parser {
    case "label =" " "? "\""
    lbl = ((![\"] .)*) ws* "\"": decode_html(Text.to_string(lbl));
  }

  shape = parser {
    case b="box" : b
    case b="diamond" : b
  }

  edge_parser = parser {
    case ws* start=name " -> " end=name ws* "[" label=label "]" ws* ";" ws*:
      {start: start, end: end, label: String.strip(label)}
  }

  start_vertex = parser {
    case ws* n=name ws* "[id=\"" id=name
    "\",URL=\"javascript:show_info('\\N');\",fillcolor=white,style=filled,":
      {name: n, id: id};
  }

  vertex_parser = parser {
    case begin=start_vertex "];":
      {id: begin.id, label: "", shape: "box"};
    case begin=start_vertex
    label=label ",shape=" shape=shape "];":
      {id: begin.id, label: label, shape: shape};
    case begin=start_vertex "shape=" shape=shape "];":
      {id: begin.id, label: "", shape: shape};
  }

  graph_parser = parser {
    case "digraph cfg \{"
    edges=edge_parser*
    vertices=vertex_parser* ws*
    "\}" ws*: {vertices: vertices, edges: edges}
  }
}