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
        option(call) c = Model.get_call_by_line(id, line);
        set_information(c, line);
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
        option(call) c = Model.get_call_by_line(id, line);
        Log.debug("src", "{c}");
        set_information(c, line)
        Dom.set_attribute_unsafe(#loc-container, "data-line","{line}")
        Log.debug("View","loc");
    }
  }

  client function void set_information(option(call) c, int line){
    res = match(c){
      case {none}: <h3>No information available</h3>
      case {some: cl}:
        <>
          <h3>Line {line}</h3>
          <h4>Context: </h4>
            {Ana.print_analysis(cl.context)}
          <h4>Path: </h4>
            {Ana.print_analysis(cl.path)}
        </>
    }
    _ = Dom.put_inside(#loc-container, Dom.of_xhtml(res));
    void
  }

  pretty_print = %%Prettify.prettify%%
  register_handler = %%Util.register_line_handler%%

}