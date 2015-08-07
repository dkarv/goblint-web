module Src{

  client function show(){
    match(View.get_analysis_id()){
    case {none}:
      Log.error("src", "analysis not finished yet");
    case {some: id}:
      src = Model.get_src(id);
      Log.debug("src", "{src}");
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

  client function callback(line){
    match(View.get_analysis_id()){
      case {none}:
        Log.error("src","clicked line but found no ana id");
      case {some: id}:
        option(call) c = Model.get_call_by_line(id, line);
        Log.debug("src", "{c}");
        res = match(c){
          case {none}: <h3>No information available</h3>
          case {some: cl}:
            <>
              <h3>{cl.file}:{line}</h3>
              <h4>Context: </h4>
                {Ana.print_analysis(cl.context)}
              <h4>Path: </h4>
                {Ana.print_analysis(cl.path)}
            </>
        }
        Dom.put_inside(#loc-container, Dom.of_xhtml(res));
        Log.debug("View","loc");
    }
  }

  // Javascript Binding to /resources/bind/dotrenderer.render(string)
  pretty_print = %%Prettify.prettify%%
  register_handler = %%Util.register_line_handler%%

}