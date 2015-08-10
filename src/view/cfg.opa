module Cfg{

  client function show(){
    match(View.get_analysis_id()){
      case {none}:
        Log.error("cfg", "analysis not finished yet");
      case {some: id}:
        match(Model.get_cfg(id)){
          case {none}:
            Log.error("Cfg","No cfg found");
          case {some: g}:
            Tab.show(#cfg-tab);
            %%Util.pushState%%("/ana/" ^ id ^ "/cfg");
            %%DotRenderer.draw%%(g, callback);
        }
    }
  }

  client function callback(line){
    match(View.get_analysis_id()){
      case {none}:
        Log.error("src","clicked line but found no ana id");
      case {some: id}:
        option(call) c = Model.get_call_by_id(id, line);
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
        Dom.put_inside(#loc-container2, Dom.of_xhtml(res));
        Log.debug("View","loc");
    }
  }

  client function search_change(_){
    string query = Dom.get_value(#search_cfg);
    Log.debug("Cfg","search changed to: {query}");
    %%DotRenderer.search%%(query);
  }
}