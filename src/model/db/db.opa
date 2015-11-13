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
    ?/anas/all[id == id]/run/id_calls[line_id];
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
    /anas/all[id == id]/run/id_calls;
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
}