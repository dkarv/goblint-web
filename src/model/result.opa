// leaf or node
type elem = {string text, option(string) id} or {string text, option(string) id, list(elem) children}
type loc = {string file, string fun, int line, string fun2, list(elem) context, list(elem) values}

module Result{
  /* returns a map (line number -> loc), containing all warnings, ...*/
  function intmap(loc) start_parsing(input){
    // matches all whitespace, newline, tabs
    ws = parser {
      case (" "|"\n"|"\r"|"\t")
    }

    str = parser {
      case "\"" s=((![\"] .)*) "\"": Text.to_string(s)
    }

    id_parser = parser {
      case " id=" i=str: {some: i}
      case "": {none}
    }

    recursive elem_parser = parser {
      case ws*
        ("<Leaf" | "<Node" ) " text=" txt=str id=id_parser "/>"
        ws*: {text: txt, ~id }
      case ws*
        "<Node text=" txt=str id=id_parser ">"
          children = elem_parser*
        "</Node>" ws*: {text: txt, children: children, ~id }
    }

    loc_parser = parser {
      case ws*
        "<Loc file=" file=str
        " line=" num=str
        " fun=" fun=str
        ">" ws*
          "<Node text=" child=str ">" ws*
            context = elem_parser ws*
            values = elem_parser ws*
          "</Node>" ws*
        "</Loc>" ws*:
          {file: file, line: Int.of_string(num), fun: fun,
            fun2: child,
            context: match(context){
              case {~children, ...}: children
              default: List.empty
            },
            values: match(values){
              case {~children, ...}: children
              default: List.empty
            }
          }
    }

    analysis_parser = parser {
      case "<analysis name=" ~str ">"
        locs = loc_parser*
        "</analysis>"
        ws*: Map.From.assoc_list(List.map(function(ll) { (ll.line, ll) },locs))
    }

    Parser.parse(analysis_parser, input);
  }
}