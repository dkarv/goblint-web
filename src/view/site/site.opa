module Site {
  client function get_analysis_id(){
    Dom.get_attribute(#tabs, "ana-id");
  }

  client function show_spinner(){
    // TODO
    Log.debug("View","loading...")
  }

  /* is called async from the server after the command to do an analysis has finished. */
  client function analysis_finished(id) {
    Log.debug("view","analysis finished");
    Dom.remove_class(#cfg-tab-parent, "disabled");
    Dom.remove_class(#src-tab-parent, "disabled");

    Dom.set_attribute_unsafe(#tabs, "ana-id", id);
    Cfg.reload(id);
    Src.reload(id);
  }
}