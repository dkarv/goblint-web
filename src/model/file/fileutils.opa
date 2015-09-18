module FileUtils {
  /** read the content of a file as string */
  function string read(path) {
    Binary.to_string(File.read(path));
  }

  function void write(string path, binary content){
    File.write(path, content);
  }

  exposed function ls(string path){
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
            case {file: _}:
              {gt};
            }
        case {file: f1}:
          match(b){
            case {dir: _}:
              {lt};
            case {file: f2}:
              String.ordering(f2, f1);
            }
      }
    },match(File.readdir(path)){
      case {success: ls}:
        LowLevelArray.filter_map_to_list(function(elem){
          {some:
            if(File.is_directory(path ^ elem)){
              {dir: elem}
            }else{
              {file: elem}
            }
          }
        }, ls);
      case {failure: _}:
        []
      });
  }
}