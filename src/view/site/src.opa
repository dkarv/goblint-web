module Src{

  client function show(){
    match(Site.get_analysis_id()){
    case {none}:
      Log.error("src", "analysis not finished yet");
    case {some: id}:
      src = Model.get_src(id);
      Tab.show(#src-tab);
      Dom.set_text(#src-container, src);
      // pretty print refuses to pretty print again if class prettyprinted is there
      Dom.remove_class(#src-container, "prettyprinted");
      pretty_print();
      register_handler("click",callback);
      %%Util.pushState%%("/ana/" ^ id ^ "/src");
      Log.debug("Src","ready with source");
    }
  }

  client function reload(string id){
    dom parent = Dom.select_id("src-tab-parent");
    active = Dom.has_class(parent, "active");
    if(active){
      %%Util.pushState%%("/ana/" ^ id ^ "/src");
      src = Model.get_src(id);
      Dom.set_text(#src-container, src);
      // pretty print refuses to pretty print again if class prettyprinted is there
      Dom.remove_class(#src-container, "prettyprinted");
      pretty_print();
      // reload the local information
      string line_str = Dom.get_attribute_unsafe(#loc-container, "data-line");
      Log.debug("Src", "try to show line: {line_str}");
      if(String.is_empty(line_str) == {false}){
        int line = Int.of_string(line_str);
        c = Model.get_call_by_line(id, line);
        list(analysis) globs = Model.get_globs(id);
        Site.set_information(#loc-container, c, globs, line_str);
        Log.debug("Src", "reloaded information");
      }
      Log.debug("Src", "ready with reloading src")
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

}