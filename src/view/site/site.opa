module Site {
  client function get_analysis_id(){
    Dom.get_attribute(#tabs, "ana-id");
  }

  client function hide_message(){
    Dom.set_style_property_unsafe(#message, "display", "none");
  }

  client function show_message(string msg, bool error){
    Dom.set_style_property_unsafe(#message, "display", "block");
    if(error){
      Dom.remove_class(#message, "alert-success");
      Dom.add_class(#message, "alert-danger");
    }else{
      Dom.add_class(#message, "alert-success");
      Dom.remove_class(#message, "alert-danger");
    }

    Dom.set_html_unsafe(#message-content, msg);
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

        show_message(message, {false});
      case {some: str}:
        show_message(message ^ "<br/>" ^ str, {true});
    }
  }
}