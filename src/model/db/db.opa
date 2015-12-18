database anas {
  ana /all[{id}]
}

module Database {
  exposed function get_src(id){
    FileUtils.read(/anas/all[{id: id}]/filename);
  }

  exposed function get_cfg(id){
    /anas/all[{id: id}]/cfg;
  }

  exposed function get_start_nodes(id){
    /anas/all[{id: id}]/start_nodes;
  }

  exposed function option(call) get_call_by_line(string id, int line) {
    ?/anas/all[id == id]/run/line_calls[line];
  }

  exposed function option(call) get_call_by_id(string id, string line_id) {
    line = ?/anas/all[id == id]/run/id_to_line[line_id];
    match(line){
      case {none}: {none}
      case {some: s}: get_call_by_line(id, s);
    }
  }

  exposed function list(analysis) get_globs(string id){
    /anas/all[id == id]/run/globs;
  }

  exposed function list(string) get_unreachables(string id){
    /anas/all[id == id]/run/unreachables;
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
    // FIXME: why is this necessary at all? avoid to materialize the whole db
    // /anas/all[id == id]/run/id_calls;
    Map.empty;
  }

  function save_filename(string id, string filename){
    /anas/all[{id: id}]/filename <- filename;
  }

  function save_graph(string id, list(string) start_nodes, graph g){
    /anas/all[{id: id}]/cfg <- g;
    /anas/all[{id: id}]/start_nodes <- start_nodes;
  }

  function save_run(string id, run r){
    /anas/all[~{id}]/run <- r;
  }

  function get_run(string id){
    /anas/all[~{id}]/run;
  }

  // for the new parser:
  function save_parameter(string id, string parameter){
    Log.debug("save_parameter:","{id}");
    /anas/all[~{id}]/run/parameters <- parameter;
  }

  function add_file(string id, file){
    Log.debug("add_file:","{file.path}");
    /anas/all[~{id}]/run/files[file.path] <- file;
  }

  function add_fkt(string id, string file_path, fkt){
    Log.debug("add_fkt:","{file_path} -> {fkt.name}");
    /anas/all[~{id}]/run/files[file_path]/fkt[fkt.name] <- fkt;
  }

  function add_fkt_node(string id, string file_path, string fkt_name, string node){
    Log.debug("add_fkt_node:","{fkt_name} -> {node}");
    /anas/all[~{id}]/run/files[file_path]/fkt[fkt_name]/nodes <+ node;
  }

  function add_call(string id, call c){
    Log.debug("add_call:","{c.id},{c.line}");
    /anas/all[~{id}]/run/line_calls[c.line] <- c;
    /anas/all[~{id}]/run/id_to_line[c.id] <- c.line;
    /anas/all[~{id}]/run/call_ids <+ c.id;
  }
}