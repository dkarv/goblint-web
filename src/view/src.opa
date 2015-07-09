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
        option(call) c = Model.get_call(id, line);
        Log.debug("src", "{c}");
        res = match(c){
          case {none}: <h3>No information available</h3>
          case {some: cl}:
            <>
              <h3>{cl.file}:{line}</h3>
              <h4>Context: </h4>
                {print_analysis(cl.context)}
              <h4>Path: </h4>
                {print_analysis(cl.path)}
            </>
        }
        Dom.put_inside(#loc-container, Dom.of_xhtml(res));
        Log.debug("src","done");
    }
  }

  client function print_analysis(ana){
    <>
      {List.map(function(an){
        <>
          <h5>{an.name}:</h5>
          {print_value(an.val)}
        </>},
      ana)}
    </>;
  }

  client function xhtml print_value(val){
    match(val){
    case ~{map}:
      <ul>{List.fold(function((key,val), acc){
          <>
            {acc}
            <li>{key}: -> {val}</li>
          </>
        },
        Map.To.assoc_list(Map.map(print_value, map)), <></>)}</ul>
    case ~{set}:
      <ul>{List.fold(function(el, acc){
        <>
          {acc}
          <li>{el}</li>
        </>},set, <></>)}</ul>
    case ~{data}:
      <span>{data}</span>
    }
  }

  // Javascript Binding to /resources/bind/dotrenderer.render(string)
  pretty_print = %%Prettify.prettify%%
  test = %%Util.test%%
  register_handler = %%Util.register_line_handler%%

}