module Cfg{

  client function show(){
    match(View.get_analysis_id()){
      case {none}:
        Log.error("cfg", "analysis not finished yet");
      case {some: id}:
        match(Model.get_analysis(id).dotfile){
          case {none}:
            Log.error("cfg", "no cfg found");
          case {some: dot}:
            Log.debug("view", "{dot}");
            Tab.show(#cfg-tab);
            render_graph(String.replace("box","rect",dot));
            %%Util.pushState%%("/ana/" ^ id ^ "/cfg");
        }
    }
  }

  render_graph = %%DotRenderer.render%%
}