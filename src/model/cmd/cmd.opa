type parameters = {
  string goblint,
  bool localmode,
  string startfolder,
  option(string) testfile,
  option(string) opentests,
  option(string) debugparser
}

module Cmd {
  parameters defaults = {
    goblint: "../analyzer/goblint",
    localmode: false,
    startfolder: "/",
    testfile: {none},
    opentests: {none},
    debugparser: {none}};

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
      },
      { CommandLine.default_parser with
        names: ["--testfile"],
        description: "give a directory or file that will be parsed recursively for .c files. goblintweb is tested with all these files",
        param_doc: "<string>",
        on_param: function(state) {
          parser { case y=Rule.consume: {no_params: {state with testfile: {some: y}}}}
        }
      },
      { CommandLine.default_parser with
        names: ["--opentests"],
        description: "open tests in browser. specify the executable that is used to open urls here. example: \"google-chrome\"",
        param_doc: "<string>",
        on_param: function(state) {
          parser { case y=Rule.consume: {no_params: {state with opentests: {some: y}}}}
        }
      },
      { CommandLine.default_parser with
        names: ["--debugparser"],
        description: "debug the result parser with this file",
        param_doc: "<string>",
        on_param: function(state){
          parser {case y=Rule.consume: {no_params: {state with debugparser: {some: y}}}}
        }
      }
    ]
  }

  parameters args = CommandLine.filter(par_family)

  function startfolder(){
    args.startfolder;
  }

  function localmode(){
    args.localmode;
  }

  function testfile(){
    args.testfile;
  }

  function opentests(){
    args.opentests;
  }

  function debugparser(){
    args.debugparser;
  }
}