module Cfg{

  client function show(){
    match(Site.get_analysis_id()){
      case {none}:
        Log.error("cfg", "analysis not finished yet");
      case {some: id}:
        g = Database.get_cfg(id);
        Tab.show(#cfg-tab);
        load(id, g);
        // set the arguments
        Site.load_arguments(id);
    }
  }

  client function load(string id, g){
    %%Util.pushState%%("/ana/" ^ id ^ "/cfg");
    %%DotRenderer.draw%%(g, callback);

    Dom.set_value(#collapse-sel, "none");
    if(search_changed() == false){
      // get the list of dead nodes and highlight them
      unreach = Database.get_unreachables(id);
      %%DotRenderer.highlight%%(unreach, "red");
    }
  }

  /** if is displayed right at the moment, reload the cfg */
  client function reload(string id){
    dom parent = Dom.select_id("cfg-tab-parent");
    if(Dom.has_class(parent, "active")){
      g = Database.get_cfg(id);
      load(id, g);
      string line_str = Dom.get_attribute_unsafe(#loc2-container, "data-line");
      Log.debug("Src", "try to show line: {line_str}");
      if(String.is_empty(line_str) == {false}){
        c = Database.get_call_by_id(id, line_str);
        list(analysis) globs = Database.get_globs(id);
        Site.set_information(#loc2-container, c, globs, line_str);
      }
    }
  }

  client function callback(line_id){
    match(Site.get_analysis_id()){
      case {none}:
        Log.error("src","clicked line but found no ana id");
      case {some: id}:
        c = Database.get_call_by_id(id, line_id);
        Log.debug("Cfg","call: {c}");
        list(analysis) globs = Database.get_globs(id);
        Site.set_information(#loc2-container, c, globs, line_id);
        Dom.set_attribute_unsafe(#loc2-container, "data-line","{line_id}");
        Log.debug("View","loc");
    }
  }

  client function collapse_change(_){
    val = Dom.get_value(#collapse-sel);
    collapse_level = match(val){
      case "none": {none};
      case "inout1": {inout1};
      case "allloops": {loops: 0};
      default: {none};
    }
    match(Site.get_analysis_id()){
      case {some: id}:
        graph g = GraphCollapse.collapse(collapse_level, id);
        %%DotRenderer.draw%%(g, callback);
      case {none}:
        Log.error("Cfg","no analysis id found");
    }
  }

  client function search_change(_){
    _ = search_changed();
    void
  }

  /**
   * returns whether there was a search query
   */
  client function bool search_changed(){
    string query = Dom.get_value(#search_cfg);
    if((query == "") == false){
      match(Site.get_analysis_id()){
        case {some: id}:
          option(list(string)) ls = Search.parse_and_search(id, query);
            match(ls){
              case {some: ss}:
                %%DotRenderer.highlight%%(ss, "green");
                Site.hide_message();
                Dom.set_style_property_unsafe(#search_cfg, "border-color", "#3c763d");
              case {none}:
                Dom.set_style_property_unsafe(#search_cfg, "border-color","#a94442");
                Site.show_message("You have a syntax error in your expression", true);
            }
        case {none}:
          Log.error("Cfg","no analysis id found");
      }
      true
    } else {
      false
    }
  }
}