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
  client function analysis_finished(result, string message) {
    Log.debug("view","analysis finished");

    match(result){
      case {success: id}:
        Dom.set_attribute_unsafe(#tabs, "ana-id", id);

        Dom.remove_class(#cfg-tab-parent, "disabled");
        Dom.remove_class(#src-tab-parent, "disabled");

        Cfg.reload(id);
        Src.reload(id);

        show_message(String.replace("\n", "<br/>", message), false);
      case {error: msg}:
        show_message(message ^ "<br/>" ^ msg, true);
    }
  }

  client function void set_information(dom target, option(call) c, list(analysis) globs, string line_id){
    res = match(c){
      case {none}: <h3>No information available</h3>
      case {some: cl}:
        <>
          <h3>{line_id}:</h3>
          <h4>Context: </h4>
          {Ana.print_analysis(cl.context)}
          <h4>Path: </h4>
          {Ana.print_analysis(cl.path)}
        </>
    }

    glob = if(List.is_empty(globs)){
      <h4>No Globs</h4>
    }else{
      <>
        <h4>Globals: </h4>
        {Ana.print_analysis(globs)}
      </>
    }

    _ = Dom.put_inside(target, Dom.of_xhtml(<>{res}{glob}</>));
    void
  }

  function void load_arguments(string id){
    string file_path = Database.get_file_path(id);
    xhtml args = ViewArguments.to_html(ViewArguments.get_defaults({some: file_path}));
    _ = Dom.put_inside(#arguments, Dom.of_xhtml(args));
    void
  }
}