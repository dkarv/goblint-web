type parameters = {string goblint, bool localmode, string startfolder, bool testmode}

module Cmd {
  parameters defaults = {goblint: "../analyzer/goblint", localmode: false, startfolder: "/", testmode: false};
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
        names: ["--tests"],
        description: "run the unit tests and exit afterwards",
        param_doc: "<bool>",
        on_param: function(state) {
          parser { case y=Rule.bool: {no_params: {state with testmode: y}}}
        }
      }
    ]
  }

  parameters args = CommandLine.filter(par_family)

  function string startfolder(){
    args.startfolder;
  }

  function bool localmode(){
    args.localmode;
  }

  function bool testmode(){
    args.testmode;
  }

}