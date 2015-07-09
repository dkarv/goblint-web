module View {

  client function get_analysis_id(){
    Dom.get_attribute(#tabs, "ana-id");
  }

  client function analysis_finished(id) {
    Log.debug("view","analysis finished");
    Dom.remove_class(#cfg-tab-parent, "disabled");
    Dom.remove_class(#src-tab-parent, "disabled");

    //Dom.set_attribute_unsafe(link, "href","/analysis/" ^ ana.id)
    Dom.set_attribute_unsafe(#tabs, "ana-id", id)
  }

  // displays the whole page
  function show_root() {
    html = <>
      {Pages.menu({upload}, [{upload}, {src}, {cfg}],[{src}, {cfg}])}
      {Pages.tabs({upload},[{upload},{src},{cfg}])}
      <a href="#" onclick={function(_) {Model.debug_parser()}}>Test Parser</a>
      </>
    Resource.page("Goblint | Upload", html);
  }

  function show_analysis(id, tab t){
    html =
    <>
      {Pages.menu(t, [{upload}, {src}, {cfg}],[])}
      {
        Xhtml.add_attribute_unsafe("ana-id", id,
        Pages.tabs(t, [{upload}, {src}, {cfg}]))
      }
    </>
    Resource.page("Goblint | {t}", html);
  }

  function list((string, arg)) parse_arguments(){
    list(string) keys = Arguments.get_keys();
    List.map(function(s){
      //elem = #s;
      ("test", {str: "asdf"})
    }, Arguments.get_keys());
  }
}
