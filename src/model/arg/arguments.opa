/* type that represents command line arguments for goblint */
type arg = {string val} or
  {int i} or
  {bool bln} or
  {list(string) opts, int sel} or
  {list(string) opts, list(int) sels} or
  {list((string,arg)) section}

module Arguments{
  /** store the default arguments in a global mutable.*/
  Mutable.t(option(list((string, arg)))) global_arg = Mutable.make({none})

  /* arguments necessary for this webinterface. */
  list((string, arg)) fixed = [
    ("outfile", {val: "result.xml"}),
    ("result", {val: "fast_xml"}),
    ("exp", {section: [("cfgdot",{bln: true})]}),
    ("justcfg", {bln: true})]

  /** get the default arguments. */
  function get_defaults(option(string) sourcefile){
    args = match(global_arg.get()){
      case ~{some}:
        some
      case {none}:
        ls = parse_args();
        global_arg.set({some: ls});
        ls;
    };

    re = match(sourcefile){
      case {none}:
        args
      case {some: path}:
        functions = parse_functions(path);
        List.map(function((s, elem)){
          match(s){
          case "mainfun":
            // select main if it exists. otherwise just select the 0th function.
            // if there is no 0th function, select main
            option(int) index = List.index("main",functions);
            match(index){
              case {some: i}:
                (s, {opts: functions, sels: [i]});
              case {none}:
                if(List.check_length(functions, 1)){
                  (s, {opts: functions, sels: [0]});
                }else{
                  (s, elem);
                }
            }
          case "exitfun":
            (s, {opts: functions, sels: []});
          case "otherfun":
            (s, {opts: functions, sels:
              List.mapi(function(i,_){i}, functions)});
          default:
            (s, elem)
          }
        }, args);
    }

    re;
  }

  /** only return the keys of the arguments. */
  function get_keys(option(string) sourcefile){
    List.map(function((a,_)){a}, get_defaults(sourcefile));
  }

  function list((string, arg)) parse_args(){
    _ = System.exec(Cmd.args.goblint ^ " --writeconf conf.json", "");
    string content = FileUtils.read("conf.json");
    match(Json.deserialize(content)){
      case ~{some}:
        dir = File.dirname(Cmd.args.goblint);
        list(string) analyses = parse_analyses(dir);
        args = parse_arg(some);
        if(List.is_empty(analyses)){
          args
        }else{
          // make analyses suggestions if parsing analyses was successful
          List.map(function(ar){
            match(ar){
              case ("ana", {section: ls}):
                ("ana", {section:
                  List.map(function(ag){
                    match(ag){
                      case ("activated", {val: val}):
                        ("activated", replace_analysis(analyses, val));
                      case ("ctx_insens", {val: val}):
                        ("ctx_insens", replace_analysis(analyses, val));
                      case ("path_sens", {val: val}):
                        ("path_sens", replace_analysis(analyses, val));
                      default: ag
                    }
                }, ls)})
              default: ar;
            }
          }, args );
        }
      case {none}: []
    }
  }

  function replace_analysis(list(string) analyses, string oldval){
    sels = List.filter_map(function(r){ r },
      List.mapi(function(i, ana){
        if(String.contains(oldval, ana)){
          {some: i}
        }else{
          {none}
        }
      }, analyses));
    {opts: analyses, ~sels}
  }

  /** changes the arguments in the second parameter if they are in the first list. */
  recursive function replace_fixed(list((string, arg)) fixed, (string, arg) (s,a)){
    match(List.find(function((str,_)){s == str}, fixed)){
      case {none}: (s,a);
      case {some: (s2,a2)}:
        match(a2){
          case {section: fixed_section}:
            match(a){
              case {section: other_section}:
                (s,{section: List.map(replace_fixed(fixed_section,_),other_section)});
              default: @fail("fixed argument is section {fixed_section}, but the other one not: {a}");
            }
          default: (s2, a2);
        }
    };
  }

  /** parse the conf.json file*/
  recursive function list((string, arg)) parse_arg(RPC.Json.json txt){
    match(txt){
      case {Record: ls}:
        List.map(replace_fixed(fixed,_),
        List.map(function((string, RPC.Json.json) (s,elem)){
          match(elem){
            case {Bool: t}: (s,{bln: t});
            case {String: str}: (s,{val: str});
            case {Int: i}: (s,~{i})
            case {List: ls}:
              (s,{val: "[" ^ String.concat(",", List.map(function(elem){
                match(elem){
                  case {String: s}: s;
                  case {Int: i}: String.of_int(i);
                  default: @fail("unknown list element: {elem}");
                }
              },ls)) ^ "]"} );
            case {Record: _}:
              (s, {section: parse_arg(elem)});
            default:
              @fail("can't parse: {elem}")
          }
        },ls));
      default:
        @fail("unknown value: {txt}");
    }
  }

  function string analyzer_call(list((string, arg)) args){
    string analyzer = Cmd.args.goblint;

    string arguments =
      String.concat(" ",
        List.map(print_arg("",_),args));
    analyzer ^ " " ^ arguments;
  }

  function string print_arg(string prefix,(string,arg) (s, a)){
    match(a){
      case {bln: {true}}: "--enable " ^ prefix ^ s;
      case {bln: {false}}: "--disable " ^ prefix ^ s;
      case {i: i}: "--set " ^ prefix ^ s ^ " \"" ^ String.of_int(i) ^ "\"";
      case ~{val}:
        string value =
          if(String.is_empty(val)){
            "'" ^ val ^ "'"
          }else{
            if(String.get(0,val) == "["){
              "[" ^ String.concat(",",
                List.map(function(s){"'" ^ s ^ "'"},
                  String.explode(",",
                    String.substring(1,String.length(val) - 2, val)
              ))) ^ "]";
            }else{ "'" ^ val ^ "'" }
          }
        "--set " ^ prefix ^ s ^ " \"" ^ value ^ "\"";
      case ~{opts,sels}: "--set " ^ prefix ^ s ^ " \"[" ^ print_opt(opts, sels) ^ "]\"";
      case ~{opts, sel}: "--sets " ^ prefix ^ s ^ " \"'" ^ print_opt(opts, [sel]) ^ "'\"";
      case ~{section}:
        String.concat(" ",
          List.map(function(ar){ print_arg(prefix ^ s ^ ".", ar)}, section));
    }
  }

  function string print_opt(list(string) opts, list(int) sels){
    String.concat(",",
      List.map(function(s){"'" ^ s ^ "'" },
        List.filteri(function(i, _){ List.mem(i,sels); },opts)));
  }

  private function list(string) parse_functions(string sourcefile){
    string out = System.exec(
      "grep -Po \"(^int|^char|^void)[^\\(]+\\([^\\)]*\\)\" {sourcefile} | cut -d\" \" -f2 | cut -d\"(\" -f1","");
    Log.debug("Arg","out: {out}");
    outs = String.explode("\n",out);
    outs = List.filter(
      function(str){String.check_substring(str, 0, "*") == false},
      outs);
    outs;
  }

  private function list(string) parse_analyses(string goblint_dir){
    string out = System.exec(
      "grep -Proh \"(?<=let name = \\\")[^\\\"]+(?=\\\")\" {goblint_dir}/src/analyses/","");
    outs = String.explode("\n",out);
    Log.debug("Anas","{outs}");
    outs
  }
}