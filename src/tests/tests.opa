module Tests {
  @async function void test(){
    if(Cmd.testmode()){
      Log.debug("Tests","starting");
      parse_test("../analyzer/tests/regression/");
      Log.debug("Tests","finished");
      System.exit(0);
    }else{
      Log.debug("Tests","skipped");
    }
  }
  a =
    test();

  function void parse_test(string path){
    List.iter(function(elem){
      match(elem){
        case {file: f}:
          if(String.has_suffix(".c", f)){
            Model.process_file(function(_,stdout,msg){
              match(msg){
                case {some: m}:
                  Log.warning("parse_test","fail: {path}{f}:\n{m}\n{stdout}\n");
                case {none}:
                  void
              }
            }, path ^ f,Arguments.get_defaults())
          }
        case {dir: d}:
          parse_test(path ^ d ^ "/");
      }
    }, FileUtils.ls(path));
  }
}