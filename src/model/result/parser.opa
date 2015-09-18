/** will be deprecated once goblint offers json output */
module ResultParser {
  function option(RPC.Json.json) find(list((string, RPC.Json.json)) ls, string str){
    match(List.find(function ((name, value)) {name == str},ls)){
      case {some: (_, val)}: {some: val}
      case {none}: {none}
    }
  }

  function list('a) parse_list(option(RPC.Json.json) o, (list((string, RPC.Json.json)) -> 'a) fct){
    match(o){
      case {some: {Record: r}}: [fct(r)];
      case {some: {List: l}}: List.filter_map(function(el){
        match(el) {
          case {Record: r}: {some: fct(r)};
          default:
            @fail("parsing error 0")
        }
      },l);
      case {none}: [];
      default: @fail("parsing error 1: {o}")
    }
  }

  function fkt parse_fkt(list((string, RPC.Json.json)) ls){
    string name = match(find(ls, "name")){
      case {some: {String: s}}: s;
      default: @fail("parsing error 2")
    }

    list(string) nodes = parse_list(find(ls, "node"), function(elem) {
      match(find(elem, "name")){
        case {some: {String: s}}: s;
        default:@fail("parsing error 3")
      }
    });
    ~{name, nodes}
  }

  function file parse_file(list((string, RPC.Json.json)) ls){
    string name = match(find(ls,"name")){
      case {some: {String: s}}: s;
      default: @fail("parsing error 4")
    }

    string path = match(find(ls, "path")){
      case {some: {String: s}}: s;
      default: @fail("parsing error 5")
    }

    list(fkt) fkt = parse_list(find(ls, "function"), parse_fkt);
    ~{name, path, fkt}
  }

  function option(value) parse_data(list((string, RPC.Json.json)) ls){
    match(find(ls, "data")){
      case {some: {String: s}}:
        {some: {data: String.strip(s)}}
      case {none}:
        {none}
      default:
        @fail("TODO no data? {ls}");
    }
  }

  function option(value) parse_map(list((string, RPC.Json.json)) ls){
    match(find(ls, "map")){
      case {some: {Record: r}}:
        list(string) keys = match(find(r, "key")){
          case {some: {String: s}}: [s]
          case {some: {List: rs}}: List.filter_map(function (el) {
            match(el){
              case {String: s}: {some: String.strip(s)}
              default: {none}
            }
          },rs);
          default: @fail("can't parse key list");
        }

        list(value) values = match(find(r, "value")){
          case {some: {Record: r}}: [parse_value(r)];
          case {some: {List: l}}: List.filter_map(function (el) {
            match(el){
              case {Record: r}: {some: parse_value(r)};
              default: {none}
            }
          }, l);
          default: @fail("can't parse value list");
        }

        values ++ match(find(r,"_")){
          // sometimes there is a string after the last key
          case {some: {String: s}}: [{data: String.strip(s)}];
          default: [];
        }

        {some: {map: Map.From.assoc_list(List.zip(keys, values))}}
      case {some: {String: s}}:
        // empty string
        {some: {map: Map.empty}}
      case {none}:
        {none}
      default:
        @fail("TODO no map? {ls}");
    }
  }

  function option(value) parse_set(list((string, RPC.Json.json)) ls){
    match(find(ls, "set")){
      case {some: {Record: r}} as children:
        list(value) vals = List.filter_map(function(elem){
          match(elem){
            case ("value", x):
              result = parse_list({some: x}, parse_value);
              {some: {set: result}}
            default:
              @fail("no value? {Json.to_string(elem.f2)}");
          }
        }, r);
        {some: {set: vals}}
      case {none}:
        {none}
      case {some: {String: s}}:
        {some: {set: []}}
      default:
        @fail("TODO no set? {ls}");
    }
  }

  recursive function value parse_value(list((string, RPC.Json.json)) ls){
    match(parse_data(ls)){
      case {some: d}:
        d
      case {none}:
        match(parse_map(ls)){
          case {some: m}:
            m
          case {none}:
            match(parse_set(ls)){
              case {some: s}:
                s
              case {none}:
                @fail("TODO no set, map or data: {ls}");
            }
        }
    }
  }

  function analysis parse_analysis(list((string, RPC.Json.json)) ls){
    string name = match(find(ls, "name")){
      case {some: {String: s}}: s;
      default: ""
    }

    value val = match(find(ls, "value")){
      case {some: {Record: r}}: parse_value(r);
      default: @fail("can't parse analysis.value")
    }

    ~{name, val}
  }

  function call parse_call(list((string, RPC.Json.json)) ls){
    int line = match(find(ls, "line")){
      case {some: {String: s}}: Int.of_string(s);
      default: 0;
    }

    int order = match(find(ls, "order")){
      case {some: {String: s}}: Int.of_string(s);
      default: 0;
    }

    string id = match(find(ls, "id")){
      case {some: {String: s}}: s;
      default: "";
    }

    string file = match(find(ls, "file")){
      case {some: {String: s}}: s;
      default: "";
    }

    list(analysis) context =  match(find(ls, "context")){
      case {some: {Record: r}}:
        parse_list(find(r, "analysis"), parse_analysis);
      default: []
    }

    list(analysis) path =  match(find(ls, "path")){
      case {some: {Record: r}}:
        parse_list(find(r, "analysis"), parse_analysis);
      default: []
    }

    ~{line, order, id, file, context, path}
  }


  function option(run) parse_json(json){
    match(json){
    case {Record: r1}:
      string par = match(find(r1, "parameters")){
        case {some: {String: s}}: s;
        default: @fail("Parser: no parameters?")
      }

      fs_cs = match(find(r1, "result")){
        case {some: {Record: r2}}:
          list(call) calls = parse_list(find(r2, "call"), parse_call);
          intmap(call) cs = List.fold(function(el, cs){
            Map.add(el.line, el, cs);
          }, calls, Map.empty);
          stringmap(call) cs2 = List.fold(function(el, cs2){
            Map.add(el.id, el, cs2);
          }, calls, Map.empty);
          { fs: parse_list(find(r2, "file"), parse_file),
            cs: cs, cs2: cs2}
        default: {fs: [], cs: Map.empty, cs2: Map.empty}
      }

      {some: {parameters: par, files: fs_cs.fs, line_calls: fs_cs.cs, id_calls: fs_cs.cs2}}
    default: {none}
    }
  }
}