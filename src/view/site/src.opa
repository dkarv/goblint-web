module Src{

  client function show(){
    match(Site.get_analysis_id()){
    case {none}:
      Log.error("src", "analysis not finished yet");
    case {some: id}:
      load(id);
      Tab.show(#src-tab);
      register_handler("click",callback);
      // set the arguments
      Site.load_arguments(id);
    }
  }

  client function load(string id){
    %%Util.pushState%%("/ana/" ^ id ^ "/src");
    src = Model.get_src(id);
    Dom.set_text(#src-container, src);
    // pretty print refuses to pretty print again if class prettyprinted is there
    Dom.remove_class(#src-container, "prettyprinted");
    pretty_print();

    // load the warnings
    // TODO show on which lines there's information available
    list(warning) warnings = Model.get_warnings(id);
    List.iter(function(warn){
      List.iter(function(item){
        add_warning(item.line, warn.group, item.txt)
        void
      }, warn.items);
      void
    }, warnings);
  }

  client function reload(string id){
    dom parent = Dom.select_id("src-tab-parent");
    active = Dom.has_class(parent, "active");
    if(active){
      load(id);

      // reload the local information
      string line_str = Dom.get_attribute_unsafe(#loc-container, "data-line");
      if(String.is_empty(line_str) == {false}){
        int line = Int.of_string(line_str);
        c = Model.get_call_by_line(id, line);
        list(analysis) globs = Model.get_globs(id);
        Site.set_information(#loc-container, c, globs, line_str);
      }
    }
  }

  client function callback(line){
    match(Site.get_analysis_id()){
      case {none}:
        Log.error("src","clicked line but found no ana id");
      case {some: id}:
        c = Model.get_call_by_line(id, line);
        Log.debug("Src","call: {c}");
        list(analysis) globs = Model.get_globs(id);
        Site.set_information(#loc-container, c, globs, "{line}")
        Dom.set_attribute_unsafe(#loc-container, "data-line","{line}")
    }
  }

  pretty_print = %%Prettify.prettify%%
  register_handler = %%Util.register_line_handler%%
  add_warning = %%Util.add_warning%%

}