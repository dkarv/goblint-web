type either('a, 'b) = {'a this} or {'b that}

type maybe('a) = {'a success} or {string error}

module Model {

  /** this method is called after an upload and goblint has been called already. */
  private function maybe(string) parse_everything(string file) {
    match(parse_cfg(file)){
      case ~{error}:
        // report error message
        ~{error}
      case {success: g}:
        match(parse_result()){
          case ~{error}:
            // report error message
            ~{error}
          case {success: res}:
            // no error, save everything to the database
            string random = Random.string(16);
            Database.save_filename(random, file);
            Database.save_graph(random, g);
            Database.save_run(random, res);
            // return no error
            {success: random}
        }
    }
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
    result = parse_everything(file);
    callback(result, stderr ^ stdout);
  }
  /** 3. option to trigger an analysis: tell to rerun an analysis (maybe with another configuration) */
  exposed function rerun_analysis(callback, string id, list((string, arg)) args){
    string filepath = /anas/all[{id: id}]/filename;
    process_file(callback, filepath, args);
  }
  /** 4. change the source in the frontend, rerun analysis. Save the file somewhere and analyse. */
  exposed function save_src(string src){
    string file = "input/" ^ Random.string(20) ^ ".c";
    FileUtils.write(file, Binary.of_string(src));
    file;
  }

  /** returns an error message if there was an error. */
  private function maybe(run) parse_result(){
    // xml -> json
    string out = System.execo("xml-json result.xml run",
      { System.exec_default_options with maxBuffer: 1638400 });
    // json -> object
    option(RPC.Json.json) res = Json.deserialize(out);
    match(res){
      case {none}:
        {error: "opalang parse error. maybe xml-json is not installed (globally)? npm install xml-json -g"}
      case ~{some}:
        match(ResultParser.parse_json(some)){
          case {none}:
            {error: "error while doing ResultParser.parse_json()"}
          case {some: res}:
            {success: res}
        }
    }
  }

  /** returns an error message if there was some error */
  private function maybe(graph) parse_cfg(string file){
    string cfg_folder = Uri.encode_string(file);
    // TODO do not only parse main.dot but also the other methods
    string dot_file = "cfgs/" ^ cfg_folder ^ "/main.dot";
    if(File.exists(dot_file)){
      string s = FileUtils.read(dot_file);
      option(graph) result = GraphParser.parse_graph(s);
      match(result){
        case {some: g}:
          {success: g};
        case {none}:
          {error: "Error while parsing dot file"}
      }
    }else{
      {error: "Goblint did not produce a dot file"}
    }
  }
}