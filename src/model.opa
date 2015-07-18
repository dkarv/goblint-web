type vertex = {string name, string shape, string label}
type edge = {string start, string end, string label}
type graph = {list(edge) edges, list(vertex) vertices}
type ana = { string id, string filename, string src, option(graph) cfg, option(string) dotfile, run run}

database anas {
  ana /all[{id}]
}

module Model {
  goblint =
    goblint_parser =
      {CommandLine.default_parser with
        names: ["--goblint"],
        description: "The path to goblint. By default: ../analyzer/goblint",
        function on_param(x){
          parser {
            case y=Rule.consume: {no_params: y}
          }
        }
      }
      CommandLine.filter(
      {title: "Goblint Web arguments",
       // for more arguments: change from string to record
       init: "../analyzer/goblint",
       parsers: [goblint_parser],
       anonymous: []
      });

  function save_analysis(filename, list((string, arg)) args, source) {
    string random = Random.string(8);
    /anas/all[{id: random}]/src = source;
    /anas/all[{id: random}]/filename = filename;
    save_cfg(random);
    save_result(random);
    random
  }

  exposed function get_analysis(id) {
    /anas/all[{id: id}];
  }

  exposed function get_src(id){
    /anas/all[{id: id}]/src
  }

  exposed function get_dotfile(id){
      /anas/all[{id: id}]/dotfile
    }

  exposed function option(call) get_call(id, line) {
    intmap(call) calls = /anas/all[id == id]/run/calls;
    Map.get(line, calls);
  }

  function upload_analysis(callback, list((string, arg)) args, form_data) {
    Log.debug("Model","upload");
    Map.iter(function(key, val) {
      Log.debug("Model","test");
      // save the file in a subdirectory TODO add timestamp / any other identification
      string file = "input/" ^ val.filename;
      File.write(file, val.content);
      // call goblint
      string out = System.exec(Arguments.analyzer_call(args) ^ " " ^ file, "");
      Log.info("upload","goblint: {out}");
      // save analysis cfg
      id = save_analysis(val.filename, args, Binary.to_string(val.content));
      callback(id);
      Log.error("upload","finished upload and analyzing: {id}");
    },form_data.uploaded_files);
  }

  function save_result(id){
    // xml -> json
    string out = System.exec("xml-json result.xml run", "");
    // json -> object
    option(RPC.Json.json) res = Json.deserialize(out);
    option(run) result = match(res){
      case {none}: @fail("could not parse result.xml... Please install xml-json: npm install xml-json -g");
      case ~{some}: Result.parse_json(some);
    }
    match(result){
      case {none}: @fail("Can not parse json");
      case ~{some}: /anas/all[~{id}]/run <- some; Log.info("Model", "save run to database");
    }
  }

  exposed function debug_parser(){
    // str = read_file("test.xml");
    // xmltest = Xmlns.try_parse(str);
    // Log.error("Debug Parser", "{xmltest}");
    // result = Result.parse_xml(str);
    // Log.error("Debug Parser","{result}");
    string out = System.exec("xml-json test.xml run","")
    res = Json.deserialize(out);
    string msg = match(res){
      case {none}: "could not parse the result.xml... Please install xml-json: npm install xml-json -g"
      case ~{some}:
        result = Result.parse_json(some);
        "{result}"
    }
    Log.info("Debug Msg", msg)
  }

  function save_cfg(id){
    string s = read_file("cfg.dot");
    g = parse_graph(s);
    Log.error("parse g","{g}");
    /anas/all[~{id}]/cfg <- some(g)
    /anas/all[~{id}]/dotfile <- some(s)
    s
  }

  function read_file(filename) {
    Binary.to_string(File.read(filename));
  }

  // parser for dot syntax. produces a graph
  function parse_graph(str){
    name = parser {
      case name=(([a-zA-Z0-9])*): Text.to_string(name)
    }
    // matches all whitespace, newline, tabs
    ws = parser {
      case (" "|"\n"|"\r"|"\t")
    }

    label = parser {
      case "label =" " "? "\""
        lbl = ((![\"] .)*) ws* "\"": Text.to_string(lbl)
    }

    shape = parser {
      case b="box" : b
      case b="diamond" : b
    }

    edge_parser = parser {
      case ws* start=name " -> " end=name ws* "[" label=label "]" ws* ";" ws*:
        {start: start, end: end, label: label }
    }
    vertex_parser = parser {
      case ws* name=name ws* "[shape=" shape=shape "]" ws*: {name: name, label: "", shape: shape}
      case ws* name=name ws* "[" label=label ",shape=" shape=shape "];" ws*: {name: name, label: label, shape: shape}
    }
    graph_parser = parser {
      case "digraph cfg \{"
        edges=edge_parser*
        vertices=vertex_parser*
        "\}" ws*: {vertices: vertices, edges: edges}
    }
    Parser.parse( graph_parser,str);
  }
}
