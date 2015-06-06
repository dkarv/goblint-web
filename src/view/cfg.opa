module Cfg{

  client function show_cfg(_){
    match(View.get_analysis_id()){
      case {none}:
        Log.error("cfg", "analysis not finished yet");
      case {~some}:
        match(Model.get_analysis(some).dotfile){
          case {none}:
            Log.error("cfg", "no cfg found");
          case {some: dot}:
            Log.debug("view", "{dot}");
            Tab.show(#cfg-tab);
            render_graph(String.replace("box","rect",dot));
        }
    }
  }

  render_graph = %%DotRenderer.render%%
}