type f = {string file} or {string dir}

module LocalFile {
  function html(){
    <div id=#file-selector onready={function(_){
        display(Model.args.startfolder);
      }
    }>
      <p>Test123</p>
    </div>
  }

  client function display(string path){
    ls = list(path);
    Dom.remove_content(#file-selector);
    htm = List.fold(function(elem, acc){
      e = match(elem){
        case {file: f}:
          <tr onclick={
            function(_){
              Log.debug("LocalFile","selected: {path ^ f}");
              Model.process_file(View.analysis_finished, path ^ f, View.parse_arguments("",Arguments.get_defaults()));
            }
          }>
            <td>
              <span class="glyphicon glyphicon-file"></span>
            </td>
            <td>{f}</td>
          </tr>;
        case {dir: d}:
          <tr onclick={function(_){display(path ^ d ^ "/")}}>
            <td>
              <span class="glyphicon glyphicon-folder-open"></span>
            </td>
            <td>{d}</td>
          </tr>;
      }
      <>
        {e}
        {acc}
      </>
    },ls,<></>);
    Dom.put_inside(#file-selector, Dom.of_xhtml(
      <table class="table table-hover">
        <thead>
          <tr>
            <th onclick={function(_){
                list(string) strs = String.explode_with("/", path, false);
                int n = List.length(strs);
                string str = String.concat("/",List.take(n-1, strs)) ^ "/";
                display(str);
                }}>
              <span class="glyphicon glyphicon-arrow-up"></span>
            </th>
            <th>
              <input type="text" value="{path}" class="form-control" id=#path-input
                onkeyup={function(_){
                  string value = Dom.get_value(#path-input);
                  int n = String.length(value);
                  string search =
                    if(String.char_at(value, n-1) == 47){
                      // '/'
                      "";
                    }else{
                      list(string) strs = String.explode_with("/", value, false);
                      int n = List.length(strs);
                      match(List.get(n-1, strs)){
                        case {some: s}: s;
                        case {none}: "";
                      }
                    }
                  Log.debug("LocalFile","keyup");
                  res = Dom.select_raw_unsafe("#file-selector tbody tr");
                  Dom.iter(function(a){
                    inside = Dom.select_children(a);
                    inside = Dom.select_next_one(inside);
                    text = Dom.get_text(inside);
                    if(String.contains(text, search)){
                      Dom.transition(a, Dom.Effect.show());
                    }else{
                      Dom.transition(a, Dom.Effect.hide());
                    }
                    Log.debug("LocalFile","search finished");
                  },res);
                }}
                onnewline={function(_){
                  Log.debug("LocalFile","newline");
                  string s = Dom.get_value(#path-input);
                  display(s);
                }}
                />
            </th>
          </tr>
        </thead>
        <tbody>
          {htm}
        </tbody>
      </table>));
    Log.debug("LocalFile","ready");
  }

  exposed function list(string path){
    int n = String.length(path);
    path = if(String.char_at(path, n-1) != 47 && File.is_directory(path)){
      // paths should end with '/' = 47 always
      path ^ "/";
    }else{ path }
    List.sort_with(function(a, b){
        match(a){
          case {dir: d1}:
            match(b){
              case {dir: d2}:
                String.ordering(d2, d1);
              case {file: f2}:
                {gt};
            }
          case {file: f1}:
            match(b){
              case {dir: d2}:
                {lt};
              case {file: f2}:
                String.ordering(f2, f1);
            }
        }
      },match(File.readdir(path)){
        case {success: ls}:
          LowLevelArray.filter_map_to_list(function(elem){
            //if(String.char_at(elem, 0) == 46){
            //  {none}
            //}else{
              {some:
                if(File.is_directory(path ^ elem)){
                  {dir: elem}
                }else{
                  {file: elem}
                }
              }
            //}
          }, ls);
        case {failure: err}:
          []
      });
  }
}