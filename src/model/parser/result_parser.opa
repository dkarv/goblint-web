/** will be deprecated once goblint offers json output */
module ResultParser {
  function option(RPC.Json.json) find(list((string, RPC.Json.json)) ls, string str){
    match(List.find(function ((name, _)) {name == str},ls)){
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

        values = values ++ match(find(r,"_")){
          // sometimes there is a string after the last key
          case {some: {String: s}}: [{data: String.strip(s)}];
          default: [];
        }

        {some: {map: Map.From.assoc_list(List.zip(keys, values))}}
      case {some: {String: _}}:
        // always an empty string
        {some: {map: Map.empty}}
      case {none}:
        {none}
      default:
        @fail("TODO no map? {ls}");
    }
  }

  function option(value) parse_set(list((string, RPC.Json.json)) ls){
    match(find(ls, "set")){
      case {some: {Record: r}}:
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
      case {some: {String: _}}:
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
      default: @fail("can't find line in call");
    }

    int order = match(find(ls, "order")){
      case {some: {String: s}}: Int.of_string(s);
      default: @fail("can't find order in call");
    }

    string id = match(find(ls, "id")){
      case {some: {String: s}}: s;
      default: @fail("can't find id in call");
    }

    string file = match(find(ls, "file")){
      case {some: {String: s}}: s;
      default: @fail("can't find file in call");
    }

    list(list(analysis)) contexts =
      parse_list(find(ls, "context"), parse_anas);

    list(list(analysis)) paths =
          parse_list(find(ls, "path"), parse_anas);

    anas = List.zip(contexts, paths);

    ~{line, order, id, file, anas}
  }

  function list(analysis) parse_anas(list((string, RPC.Json.json)) ls){
    parse_list(find(ls, "analysis"), parse_analysis);
  }

  function list((string, analysis)) parse_glob(list((string, RPC.Json.json)) ls){
    string key = match(find(ls, "key")){
      case {some: {String: s}}:
        s
      default:
        @fail("Found no key for glob");
    };

    List.map(function(ana){
      (key, ana)
    }, parse_list(find(ls, "analysis"), parse_analysis));
  }

  function warning parse_warning(list((string, RPC.Json.json)) ls){
    match(find(ls, "group")){
      case {some: {Record: rs}}:
        string name = match(find(rs, "name")){
          case {some: {String: s}}:
            s
          default:
            @fail("can't parse group name");
        }
        list(warnitem) items = parse_list(find(rs, "text"), parse_warnitem);

        {group: name, items: items}
      default:
        @fail("Can't parse warning group");
    }
  }

  function warnitem parse_warnitem(list((string, RPC.Json.json)) ls){
    string txt = match(find(ls, "_")){
      case {some: {String: s}}: s
      default: @fail("can't parse text of text");
    }
    string file = match(find(ls, "file")){
      case {some: {String: s}}: s
      default: @fail("can't parse file of text");
    }
    int line = match(find(ls, "line")){
      case {some: {String: s}}: Int.of_string(s);
      default: @fail("can't parse line of text");
    }
    ~{line, file, txt}
  }

  /**
   * input has to be sorted in a way that the same analysis are right nest to each other
   */
  recursive function list((string, list((string,value)))) merge_globs(list((string,analysis)) input, option((string, list((string, value)))) acc){
    match(input){
      case []:
        match(acc){
          case {none}: []
          case {some: x}: [x]
        }
      case [(var, a) | ans]:
        match(acc){
          case {none}:
            merge_globs(ans, {some: (a.name, [(var, a.val)])})
          case {some: (n, ls)}:
            if(n == a.name){
              merge_globs(ans, {some: (n, [(var, a.val) | ls])});
            }else{
              [(n, ls) | merge_globs(ans, {some: (a.name, [(var, a.val)])} )];
            }
        }
    }
  }


  function option(run) parse_json(json){
    match(json){
    case {Record: r1}:
      string parameters = match(find(r1, "parameters")){
        case {some: {String: s}}: s;
        default: @fail("Parser: no parameters?")
      }

      r2 = match(find(r1, "result")){
        case {some: {Record: r2}}:
          r2
        default: @fail("No result tag in the xml file?");
      }

      list(call) calls = parse_list(find(r2, "call"), parse_call);

      intmap(call) line_calls = List.fold(function(el, cs){
        Map.add(el.line, el, cs);
      }, calls, Map.empty);

      stringmap(call) id_calls = List.fold(function(el, cs2){
        Map.add(el.id, el, cs2);
      }, calls, Map.empty);

      list(string) call_ids = Map.To.key_list(id_calls);

      list(list((string, analysis))) raw_globs = parse_list(find(r2, "glob"), parse_glob);
      list((string, analysis)) flatten_globs = List.rev_flatten(raw_globs);
      list((string, analysis)) sorted_globs = List.sort_by(function((_, ana)){
        ana.name
      }, flatten_globs);
      list((string, list((string, value)))) merged_globs = merge_globs(sorted_globs, {none});
      list(analysis) globs = List.map(function((name, gls)){
        stringmap(value) globs = Map.From.assoc_list(gls);
        {~name, val: {map: globs}}
      }, merged_globs);

      list(warning) warnings = parse_list(find(r2, "warning"), parse_warning);

      list(file) files = parse_list(find(r2, "file"), parse_file);

      list(string) unreachables = Map.To.key_list(
        Map.filter(function(_, call){
          List.is_empty(call.anas)
        },id_calls)
      );

      {some: ~{files, line_calls, id_calls, globs, call_ids, warnings, parameters, unreachables}}
    default: @fail("the xml file seems to be broken?")
    }
  }
}