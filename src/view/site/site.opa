module Site {
  client function get_analysis_id(){
    Dom.get_attribute(#tabs, "ana-id");
  }

  client function show_spinner(){
    Dom.set_style_property_unsafe(#message, "display", "block");
    // TODO
    Log.debug("View","loading...")
  }

  client function hide_spinner(){
    // TODO remove spinner
    Log.debug("View","finished loading");
  }

  /* is called async from the server after the command to do an analysis has finished. */
  client function analysis_finished(string id, string message, option(string) error) {
    Log.debug("view","analysis finished");

    match(error){
      case {none}:
        Dom.remove_class(#cfg-tab-parent, "disabled");
        Dom.remove_class(#src-tab-parent, "disabled");

        Dom.set_attribute_unsafe(#tabs, "ana-id", id);
        Cfg.reload(id);
        Src.reload(id);

        Dom.add_class(#message, "alert-success");
        Dom.remove_class(#message, "alert-danger");
        Dom.set_text(#message-content, message);
      case {some: str}:
        Dom.remove_class(#message, "alert-success");
        Dom.add_class(#message, "alert-danger");
        Dom.set_text(#message-content, message ^ "\n" ^ str);
    }

    hide_spinner();
  }
}