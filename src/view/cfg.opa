module Cfg{

  client function show(){
    match(View.get_analysis_id()){
      case {none}:
        Log.error("cfg", "analysis not finished yet");
      case {some: id}:
        /*match(Model.get_dotfile(id)){
          case {none}:
            Log.error("cfg", "no cfg found");
          case {some: dot}:
            Log.debug("view", "{dot}");
            Tab.show(#cfg-tab);
            render_graph(String.replace("box","rect",dot));
            %%Util.pushState%%("/ana/" ^ id ^ "/cfg");
        }*/
        match(Model.get_cfg(id)){
          case {none}:
            Log.error("Cfg","No cfg found");
          case {some: g}:
            Log.debug("Cfg","graph: {g}");
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
        Dom.put_inside(#loc-container2, Dom.of_xhtml(res));
        Log.debug("View","loc");
    }
  }

  render_graph = %%DotRenderer.render%%
}