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
  // <a href="#" onclick={function(_) {Model.debug_parser()}}>Test Parser</a>
  function show_root() {
    html =
      <>
        {Pages.menu({upload}, [{upload}, {src}, {cfg}],[{src}, {cfg}])}
        {Pages.tabs({upload},[{upload}, {src}, {cfg}])}
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

  client function list((string, arg)) parse_arguments(){
    list(string) keys = Arguments.get_keys();
    List.filter_map(function(s){
      elem = Dom.select_id(s);
      option(string) attr = Dom.get_attribute(elem, "type");
      match(attr){
        case {some: "text"}:
          // TODO set or sets?
          {some: (s, {str: Dom.get_value(elem)})};
        case {some: "checkbox"}:
          {some: (s, {bln: Dom.is_checked(elem)})};
        default:
          {none};
      }
    }, Arguments.get_keys());
  }
}
