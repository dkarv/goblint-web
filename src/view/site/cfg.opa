module Cfg{

  client function show(){
    match(Site.get_analysis_id()){
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

  /** if is displayed right at the moment, reload the cfg */
  client function reload(string id){
    dom parent = Dom.select_id("cfg-tab-parent");
    if(Dom.has_class(parent, "active")){
      %%Util.pushState%%("/ana/" ^ id ^ "/cfg");
      match(Model.get_cfg(id)){
        case {none}:
          Log.error("Cfg","No cfg found");
        case {some: g}:
          %%DotRenderer.draw%%(g, callback);
          string line_str = Dom.get_attribute_unsafe(#loc2-container, "data-line");
          Log.debug("Src", "try to show line: {line_str}");
          if(String.is_empty(line_str) == {false}){
            option(call) c = Model.get_call_by_id(id, line_str);
            list(analysis) globs = Model.get_globs(id);
            Site.set_information(#loc2-container, c, globs, line_str);
            Log.debug("Src", "reloaded information");
          }
          Log.debug("Src", "ready with reloading src")
      }
    }
  }

  client function callback(line_id){
    match(Site.get_analysis_id()){
      case {none}:
        Log.error("src","clicked line but found no ana id");
      case {some: id}:
        option(call) c = Model.get_call_by_id(id, line_id);
        list(analysis) globs = Model.get_globs(id);
        Site.set_information(#loc2-container, c, globs, line_id);
        Dom.set_attribute_unsafe(#loc2-container, "data-line","{line_id}");
        Log.debug("View","loc");
    }
  }

  client function collapse_change(_){
    val = Dom.get_value(#collapse-sel);
    Log.debug("Cfg","collapse change: " ^ val);
    match(Site.get_analysis_id()){
      case {some: id}:
        option(Model.graph) g = Graph.collapse({one}, id);
        match(g){
          case {none}:
            Log.error("Cfg","There was an error: collapsing not possible");
          case {some: g}:
            Log.debug("Cfg","collapsed graph: {g}");
            %%DotRenderer.draw%%(g, callback);
        }
      case {none}:
        Log.error("Cfg","no analysis id found");
    }
  }

  client function search_change(_){
    string query = Dom.get_value(#search_cfg);
    match(Site.get_analysis_id()){
      case {some: id}:
        option(list(string)) ls = Search.parse_and_search(id, query);
          match(ls){
            case {some: ss}:
              %%DotRenderer.highlight%%(ss);
              Site.hide_message();
              Dom.set_style_property_unsafe(#search_cfg, "border-color", "#3c763d");
            case {none}:
              Dom.set_style_property_unsafe(#search_cfg, "border-color","#a94442");
              Site.show_message("You have a syntax error in your expression", true);
          }
      case {none}:
        Log.error("Cfg","no analysis id found");
    }
    Log.debug("Cfg","finished search");
  }
}