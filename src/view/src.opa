module Src{

  client function show(){
    match(View.get_analysis_id()){
    case {none}:
      Log.error("src", "analysis not finished yet");
    case {some: id}:
      src = Model.get_analysis(id).src;
      Log.debug("src", "{src}");
      Tab.show(#src-tab);
      Dom.set_text(#src-container, src);
      // pretty print refuses to pretty print again if class prettyprinted is there
      Dom.remove_class(#src-container, "prettyprinted");
      pretty_print();
      register_handler("click",callback);
      %%Util.pushState%%("/ana/" ^ id ^ "/src");
    }
  }

  client function callback(line){
    match(View.get_analysis_id()){
      case {none}:
        Log.error("src","clicked line but found no ana id");
      case {some: id}:
        loc l = Model.get_loc(id, line);
        Log.debug("src", "{l}");
        res = <>
          <h3>{l.file}:{line}</h3>
          <ul>
            {List.map(print_loc,l.values)}
          </ul>
        </>
        Dom.put_inside(#loc-container, Dom.of_xhtml(res));
        Log.debug("src","done");

    }
  }

  recursive client function print_loc(elem){
    match(elem){
      case {~children, ~text, ~id}:
        <li>{text}
          <ul>
            {List.map(print_loc, children)}
          </ul>
        </li>
      case {~text, ~id}:
        <li>{text}</li>
    }
  }

  // Javascript Binding to /resources/bind/dotrenderer.render(string)
  pretty_print = %%Prettify.prettify%%
  test = %%Util.test%%
  register_handler = %%Util.register_line_handler%%

}