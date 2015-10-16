module Tests {
  @async function void test(){
    match(Cmd.testfile()){
      case {none}:
        Log.debug("Tests","skipped");
      case {some: s}:
      Log.debug("Tests","starting");
      list(string) fails = if(File.is_directory(s)){
        parse_test(s);
      }else{
        test_file(s);
      }
      Log.debug("Tests","finished. Fails: {List.length(fails)}");
      if(List.is_empty(fails) == false){
        Log.error("Test", "there were unexpected fails:");
        List.iter(function(fail){
          Log.error("Test", "{fail}");
        }, fails)
      }
      if(Option.is_none(Cmd.opentests())){
        System.exit(0);
      }
    }
  }
  a =
    test();

  /**
   * test recursively this path. it returns the failure paths
   */
  function list(string) parse_test(string path){
    List.fold(function(elem, ls){
      match(elem){
        case {file: f}:
          if(String.has_suffix(".c", f)){
            test_file(path ^ f);
          }else{
            []
          }
        case {dir: d}:
          parse_test(path ^ d ^ "/");
      } ++ ls;
    }, FileUtils.ls(path), []);
  }

  function list(string) test_file(string file){
    Model.process_file(function(id, stdout, msg){
      match(msg){
        case {some: m}:
          Log.warning("parse_test","fail: {file}:\n{m}\n{stdout}\n");
          if( Option.is_some(List.index(file, expected_fails)) ){
            Log.debug("Test","expected fail: {file}");
            []
          }else{
            [file];
          };
        case {none}:
          match(Cmd.opentests()){
            case {none}: void
            case {some: browser}:
              _ = System.exec(browser ^ " http://localhost:8080/ana/{id}/src &", "");
              void
          }
          []
      }}, file, Arguments.get_defaults({some: file}));
  }

  list(string) expected_fails = [
    "../analyzer/tests/regression/16-relinv/01-flag.c",
    "../analyzer/tests/regression/14-osek/16-activateTask.c",
    "../analyzer/tests/regression/14-osek/15-startuphook.c",
    "../analyzer/tests/regression/14-osek/14-high_low_read_write.c",
    "../analyzer/tests/regression/14-osek/13-pretty-flags.c",
    "../analyzer/tests/regression/14-osek/12-good-flags.c",
    "../analyzer/tests/regression/14-osek/11-bad_flags2.c",
    "../analyzer/tests/regression/14-osek/10-weak_flags.c",
    "../analyzer/tests/regression/14-osek/09-resource_flags.c",
    "../analyzer/tests/regression/14-osek/08-flipped_flags.c",
    "../analyzer/tests/regression/14-osek/07-bad_flags.c",
    "../analyzer/tests/regression/14-osek/06-suffix.c",
    "../analyzer/tests/regression/14-osek/05-privatintervals.c",
    "../analyzer/tests/regression/14-osek/04-cubbyhole.c",
    "../analyzer/tests/regression/14-osek/03-example_fun.c",
    "../analyzer/tests/regression/14-osek/02-example.c",
    "../analyzer/tests/regression/14-osek/01-privatize.c",
    "../analyzer/tests/regression/13-privatized/16-opencode_offs.c",
    "../analyzer/tests/regression/13-privatized/14-opencode_dyn.c",
    "../analyzer/tests/regression/13-privatized/13-opencode_sound.c",
    "../analyzer/tests/regression/13-privatized/12-opencode_nr.c",
    "../analyzer/tests/regression/13-privatized/11-opencode_rc.c",
    "../analyzer/tests/regression/13-privatized/07-dll_example.c",
    "../analyzer/tests/regression/12-containment/01-analyse.c",
    "../analyzer/tests/regression/10-synch/04-two_mainfuns.c",
    "../analyzer/tests/regression/09-regions/25-usb_bus_list_nr.c",
    "../analyzer/tests/regression/09-regions/15-kernel_foreach_nr.c",
    "../analyzer/tests/regression/09-regions/14-kernel_foreach_rc.c",
    "../analyzer/tests/regression/09-regions/08-kernel_list_nr.c",
    "../analyzer/tests/regression/09-regions/07-kernel_list_rc.c",
    "../analyzer/tests/regression/04-mutex/40-rw_lock_rc.c",
    "../analyzer/tests/regression/04-mutex/39-rw_lock_nr.c",
    "../analyzer/tests/regression/04-mutex/34-kernel_nr.c",
    "../analyzer/tests/regression/04-mutex/33-kernel_rc.c",
    "../analyzer/tests/regression/04-mutex/32-allfuns.c",
    "../analyzer/tests/regression/02-base/31-list_type.c",
    "../analyzer/tests/regression/02-base/10-init_allfuns.c",
    "../analyzer/tests/regression/00-sanity/14-startstate.c",
  ]
}