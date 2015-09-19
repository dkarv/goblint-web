module View {

  /** display the whole page. upload tab is active */
  function show_root() {
    html =
      <div id=#content>
        {Pages.menu({upload}, [{upload}, {src}, {cfg}],[{src}, {cfg}])}
        {Pages.tabs({upload},[{upload}, {src}, {cfg}])}
      </div>
    Resource.page("Goblint | Upload", html);
  }

  /** display the page and make tab t visible */
  function show_analysis(id, tab t){
    html =
    <div id=#content>
      {Pages.menu(t, [{upload}, {src}, {cfg}],[])}
      {
        Xhtml.add_attribute_unsafe("ana-id", id,
        Pages.tabs(t, [{upload}, {src}, {cfg}]))
      }
    </div>
    Resource.page("Goblint | " ^ Pages.name(t), html);
  }
}
