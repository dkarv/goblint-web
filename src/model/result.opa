// leaf or node
type elem = {string text, option(string) id} or {string text, option(string) id, list(elem) children}
type loc = {string file, string fun, int line, string fun2, list(elem) context, list(elem) values}

/*type attributes = {string name, string value}
type xxml = {string text} or {list(xxml) content, option(string) nstag, list(attributes) attr}*/

type value = {
  stringmap(value) map
} or {
  list(value) set
} or {
  string data
}

type analysis = {
  string name,
  value val
}

type call = {
  string id,
  string file,
  int line,
  int order,
  list(analysis) context,
  list(analysis) path
}

type fkt = {
  string name,
  list(string) nodes
}

type file = {
  string name,
  string path,
  list(fkt) fkt
}

type run = {
  string parameters,
  list(file) files,
  intmap(call) calls
}

module Result{
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
          default: {none}
        }
      },l);
      default: []
    }
  }

  function fkt parse_fkt(list((string, RPC.Json.json)) ls){
    string name = match(find(ls, "name")){
      case {some: {String: s}}: s;
      default: "";
    }

    list(string) nodes = parse_list(find(ls, "node"), function(elem) {
      match(find(elem, "name")){
        case {some: {String: s}}: s;
        default: "";
      }
    });
    ~{name, nodes}
  }

  function file parse_file(list((string, RPC.Json.json)) ls){
    string name = match(find(ls,"name")){
      case {some: {String: s}}: s;
      default: "";
    }

    string path = match(find(ls, "path")){
      case {some: {String: s}}: s;
      default: "";
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
            case ("value", {Record: r}):
              {some: parse_value(r)}
            default:
              Log.debug("Result","no value? {elem}");
              {none}
          }
          /*if(name == "value"){
            // {some: parse_value(value)}
            {some: {data: "TEST"}}
          }else{
            {none}
          }*/
        }, r);
        Log.debug("Result","{children}");
        Log.debug("Result2","{vals}");
        {some: {set: vals}} //parse_list(children, parse_value)}};
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
        default: ""; // found no parameters or had wrong type
      }

      fs_cs = match(find(r1, "result")){
        case {some: {Record: r2}}:
          list(call) calls = parse_list(find(r2, "call"), parse_call);
          intmap(call) cs = List.fold(function(el, cs){
            Map.add(el.line, el, cs);
          }, calls, Map.empty);
          { fs: parse_list(find(r2, "file"), parse_file),
            cs: cs}
        default: {fs: [], cs: Map.empty}
      }

      {some: {parameters: par, files: fs_cs.fs, calls: fs_cs.cs}}
    default: {none}
    }
  }
}