type vertex = {string id, string shape, string label}
type edge = {string start, string end, string label}
type Model.graph = {list(edge) edges, list(vertex) vertices}
type ana = { string id, string filename, option(Model.graph) cfg, option(string) dotfile, run run}

type either('a, 'b) = {'a this} or {'b that}
database anas {
  ana /all[{id}]
}

module Model {

  /* do not use often. throws stackoverflows even for quite small analysis'*/
  exposed function get_analysis(id) {
    /anas/all[{id: id}];
  }

  exposed function get_src(id){
    FileUtils.read(/anas/all[{id: id}]/filename);
  }

  exposed function get_dotfile(id){
    /anas/all[{id: id}]/dotfile;
  }

  exposed function get_cfg(id){
    /anas/all[{id: id}]/cfg;
  }

  exposed function option(call) get_call_by_line(string id, int line) {
    ?/anas/all[id == id]/run/line_calls[line];
  }

  exposed function option(call) get_call_by_id(string id, string line_id) {
    ?/anas/all[id == id]/run/id_calls[line_id];
  }

  exposed function list(analysis) get_globs(string id){
    /anas/all[id == id]/run/globs;
  }

  exposed function list(warning) get_warnings(string id){
    /anas/all[id == id]/run/warnings;
  }

  exposed function string get_file_path(string id){
    /anas/all[id == id]/filename;
  }

  function list(string) get_call_ids(string id){
    /anas/all[id == id]/run/call_ids;
  }

  function stringmap(call) get_id_map(string id){
    /anas/all[id == id]/run/id_calls;
  }

  /** this method is called after an upload and goblint has been called already. */
  private function (string, option(string)) parse_analysis(file) {
    string random = Random.string(8);
    /anas/all[{id: random}]/filename = file;
    message = match(parse_cfg(random, file)){
      case {some: _} as r: r
      case {none}:
        match(parse_result(random)){
          case {some: s}: {some: s}
          case {none}: {none};
        }
    }
    (random, message)
  }



  /** 1. option to trigger an analysis: upload a file */
  function upload_analysis(callback, list((string, arg)) args, form_data) {
    Map.iter(function(_, val) {
      // save the file in a subdirectory TODO add timestamp / any other identification
      string file = "input/" ^ val.filename;
      FileUtils.write(file, val.content);
      process_file(callback, file, args);
    },form_data.uploaded_files);
  }

  /** 2. option to trigger an analysis: pass a local file path */
  exposed function process_file(callback, string file, list((string, arg)) args){
    out = System.shell_exec(Arguments.analyzer_call(args) ^ " " ^ file, "");
    stderr = out.result().stderr;
    stderr = stderr ^ if(String.is_empty(stderr)){""}else{"\n"}
    stdout = out.result().stdout;
    (id, message) = parse_analysis(file);
    Log.debug("Model","args: {args}");
    callback(id, stderr ^ stdout, message);
  }
  /** 3. option to trigger an analysis: tell to rerun an analysis (maybe with another configuration) */
  exposed function rerun_analysis(callback, string id, list((string, arg)) args){
    string filepath = /anas/all[{id: id}]/filename;
    process_file(callback, filepath, args);
  }
  /** 4. */
  exposed function save_src(string src){
    string file = "input/" ^ Random.string(20) ^ ".c";
    FileUtils.write(file, Binary.of_string(src));
    file;
  }

  /** returns an error message if there was an error. */
  private function option(string) parse_result(id){
    // xml -> json
    string out = System.execo("xml-json result.xml run",
      { System.exec_default_options with maxBuffer: 1638400 });
    // json -> object
    option(RPC.Json.json) res = Json.deserialize(out);
    either(option(run), string) result = match(res){
      case {none}:
        {that: "parse error. maybe xml-json is not installed (globally)?"}
      case ~{some}:
        {this: ResultParser.parse_json(some)}
    }
    match(result){
      case {this: {some: s}}:
        /anas/all[~{id}]/run <- s;
        // no error message
        {none}
      case {that: s}: {some: s}
      default: {some: "error while doing ResultParser.parse_json()"}
    }
  }

  exposed function debug_parser(){
    str = FileUtils.read("main.dot");
    g = parse_graph(str);
    Log.debug("Cfg","{g}");
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

  /** returns an error message if there was some error */
  private function option(string) parse_cfg(string id, string file){
    string cfg_folder = Uri.encode_string(file);
    string dot_file = "cfgs/" ^ cfg_folder ^ "/main.dot";
    if(File.exists(dot_file)){
      string s = FileUtils.read(dot_file);
      option(Model.graph) result = parse_graph(s);
      match(result){
        case {some: g}:
         /anas/all[~{id}]/cfg <- some(g);
         {none}
        case {none}:
          {some: "Error while parsing dot file"}
      }
    }else{
      {some: "Goblint did not produce a dot file"}
    }
  }

  // parser for dot syntax. produces a graph
  private function parse_graph(str){
    Parser.try_parse( graph_parser,str);
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