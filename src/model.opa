type vertex = {string id, string shape, string label}
type edge = {string start, string end, string label}
type Model.graph = {list(edge) edges, list(vertex) vertices}
type ana = { string id, string filename, option(Model.graph) cfg, option(string) dotfile, run run}

type parameters = {string goblint, bool localmode, string startfolder}

database anas {
  ana /all[{id}]
}

module Model {
  parameters defaults = {goblint: "../analyzer/goblint", localmode: false, startfolder: "/"};

  private CommandLine.family(parameters) par_family = {
    title: "Goblint Web parameters",
    init: defaults,
    anonymous: [],
    parsers: [
      { CommandLine.default_parser with
        names: ["--goblint"],
        description: "The path to goblint. Default: {defaults.goblint}",
        param_doc: "<string>",
        on_param: function(state) {
          parser { case y=Rule.consume: {no_params: {state with goblint: y}} }
        }
      },
      { CommandLine.default_parser with
        names: ["--localmode"],
        description: "show a local file explorer if enabled. Default: {defaults.localmode}",
        param_doc: "<bool>",
        on_param: function(state) {
          parser { case y=Rule.bool: {no_params: {state with localmode: y}}}
        }
      },
      { CommandLine.default_parser with
        names: ["--startfolder"],
        description: "which folder is shown first if '--localmode true'. directories should end with '/'. Default: {defaults.startfolder}",
        param_doc: "<string>",
        on_param: function(state) {
          parser { case y=Rule.consume: {no_params: {state with startfolder: y}} }
        }
      }
    ]
  }

  parameters args = CommandLine.filter(par_family);
  goblint = args.goblint;


  /** this method is called after an upload and goblint has been called already. */
  function save_analysis(file) {
    string random = Random.string(8);
    /anas/all[{id: random}]/filename = file;
    save_cfg(random, file);
    save_result(random);
    random
  }

  /* do not use often. throws stackoverflows even for quite small analysis'*/
  exposed function get_analysis(id) {
    /anas/all[{id: id}];
  }

  exposed function get_src(id){
    read_file(/anas/all[{id: id}]/filename);
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
    Map.iter(function(key, val) {
      // save the file in a subdirectory TODO add timestamp / any other identification
      string file = "input/" ^ val.filename;
      File.write(file, val.content);
      process_file(callback, file, args);
    },form_data.uploaded_files);
  }

  exposed function process_file(callback, string file, list((string, arg)) args){
    string out = System.exec(Arguments.analyzer_call(args) ^ " " ^ file, "");
    Log.info("upload","goblint: {out}");
    // save analysis, graph, ...
    id = save_analysis(file);
    callback(id);
    Log.debug("upload","finished upload and analyzing: {id}");
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

  function void save_cfg(string id, string file){
    string cfg_folder = Uri.encode_string(file);
    string s = read_file("cfgs/" ^ cfg_folder ^ "/main.dot");
    Model.graph g = parse_graph(s);
    Log.debug("Cfg","{g}");
    /anas/all[~{id}]/cfg <- some(g);
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
        {start: start, end: end, label: String.strip(label) }
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
