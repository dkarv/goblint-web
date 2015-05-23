type vertex = {string name, string shape, string label}
type edge = {string start, string end, string label}
type graph = {list(edge) edges, list(vertex) vertices}
type ana = { string id, string filename, string src, option(graph) cfg, option(string) dotfile}

database anas {
  ana /all[{id}]
}

module Model {

  function save_analysis(filename, source) {
    string random = Random.string(8);
    /anas/all[{id:random}]/src = source;
    /anas/all[{id:random}]/filename = filename;
    save_cfg(random);
    //save_result(random);
    random
  }

  function get_analysis(id) {
    /anas/all[{id: id}];
  }

  function upload_analysis(callback, form_data) {
    string analyzer = "../analyzer/goblint"
    Map.iter(function(key, val) {
      // save the file in a subdirectory TODO add timestamp / any other identification
      string file = "input/" ^ val.filename;
      File.write(file, val.content);
      // call goblint
      string out = System.exec(analyzer ^ " --sets outfile result.xml --sets result indented --set justcfg true " ^ file, "");
      Log.error("upload","goblint: {out}");
      // save analysis cfg
      id = save_analysis(val.filename, Binary.to_string(val.content));
      callback(get_analysis(id));
      Log.error("upload","finished upload and analyzing: {id}");
    },form_data.uploaded_files);
  }

  function read_result(){
    read_file("result.xml");
  }

  function save_cfg(id){
    string s = read_file("cfg.dot");
    // parser not yet ready to parse everything
    // g = parse_graph(s);
    // /anas/all[~{id}]/cfg <- some(g)
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
        lbl=(([a-zA-Z0-9*_(),%+=:.\200-\377]|"&quot;"|"&gt;"|"&lt;"|"&amp;"|" "|"\\")*)
        ws* "\"": Text.to_string(lbl)
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
    graph g = Parser.parse( graph_parser,str);
    g
  }
}
