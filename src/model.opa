type vertex = {string id, string shape, string label}
type edge = {string start, string end, string label}
type Model.graph = {list(edge) edges, list(vertex) vertices}
type ana = { string id, string filename, string src, option(Model.graph) cfg, option(string) dotfile, run run}

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

  /** this method is called after an upload and goblint has been called already. */
  function save_analysis(filename, list((string, arg)) args, source) {
    string random = Random.string(8);
    /anas/all[{id: random}]/src = source;
    /anas/all[{id: random}]/filename = filename;
    save_cfg(random, filename);
    save_result(random);
    random
  }

  /* do not use often. throws stackoverflows even for quite small analysis'*/
  exposed function get_analysis(id) {
    /anas/all[{id: id}];
  }

  exposed function get_src(id){
    /anas/all[{id: id}]/src;
  }

  exposed function get_dotfile(id){
    /anas/all[{id: id}]/dotfile;
  }

  exposed function get_cfg(id){
    /anas/all[{id: id}]/cfg;
  }

  exposed function option(call) get_call_by_line(string id, int line) {
    intmap(call) calls = /anas/all[id == id]/run/line_calls;
    Map.get(line, calls);
  }

  exposed function option(call) get_call_by_id(string id, string line_id) {
      stringmap(call) calls = /anas/all[id == id]/run/id_calls;
      Map.get(line_id, calls);
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
      Log.debug("upload","finished upload and analyzing: {id}");
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

  function void save_cfg(string id, string filename){
    string cfg_folder = Uri.encode_string("input/" ^ filename);
    string s = read_file("cfgs/" ^ cfg_folder ^ "/main.dot");
    Model.graph g = parse_graph(s);
    Log.debug("Cfg","{g}");
    /anas/all[~{id}]/cfg <- some(g);
    /*string s = read_file("cfg.dot");
    g = parse_graph(s);
    Log.error("parse g","{g}");
    /anas/all[~{id}]/cfg <- some(g)
    /anas/all[~{id}]/dotfile <- some(s)
    s*/

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
      // first two cases are for the cfgout output, can be removed
      // case 1 cfgout
      case ws* name=name ws* "[shape=" shape=shape "]" ws*: {id: name, label: "", shape: shape}
      // case 2 cfgout
      case ws* name=name ws* "[" label=label ",shape=" shape=shape "];" ws*: {id: name, label: label, shape: shape}
      case ws* n=name ws* "[id=\"" id=name
        "\",URL=\"javascript:show_info('\\N');\",fillcolor=white,style=filled,];" ws*:
        {id: n, label: "", shape: "box"}
      case ws* n=name ws* "[id=\"" id=name
        "\",URL=\"javascript:show_info('\\N');\",fillcolor=white,style=filled,"
        label=label ",shape=" shape=shape "];" ws*:
        {id: n, label: label, shape: shape}
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
