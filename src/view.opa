module View {

  client function get_analysis_id(){
    Dom.get_attribute(#tabs, "ana-id");
  }

  client function show_spinner(){
    Log.debug("View","loading...")
  }

  client function analysis_finished(id) {
    Log.debug("view","analysis finished");
    Dom.remove_class(#cfg-tab-parent, "disabled");
    Dom.remove_class(#src-tab-parent, "disabled");

    Dom.set_attribute_unsafe(#tabs, "ana-id", id);
    Cfg.reload(id);
    Src.reload(id);
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

  client function list((string, arg)) parse_arguments(string prefix, list((string, arg)) defaults){
    List.map(function((s,def)){
      string selector = "[arg-id='" ^ Dom.escape_selector(s) ^ "']";
      match(def){
        case ~{val}:
          elem = Dom.select_raw_unsafe(prefix ^ "input" ^ selector);
          (s, {val: Dom.get_value(elem)})
        case ~{i}:
          elem = Dom.select_raw_unsafe(prefix ^ "input" ^ selector);
          (s, {i: Int.of_string(Dom.get_value(elem))})
        case ~{bln}:
          elem = Dom.select_raw_unsafe(prefix ^ "input" ^ selector);
          (s, {bln: Dom.is_checked(elem)})
        case ~{opts, sels}:
          elems = Dom.select_raw_unsafe(prefix ^ "select" ^ selector ^ " option:selected");
          (s, {opts:opts, sels:
            Dom.fold(function(d, l){
              match(List.index(Dom.get_value(d), opts)){
                case {some: i}: l ++ [i];
                case {none}: l;
              }
            }, [], elems)
          });
        case ~{opts, sel}:
          elem = Dom.select_raw_unsafe(prefix ^ selector);
          Log.error("View",Dom.get_value(elem));
          (s, ~{opts: opts, sel: match(List.index(Dom.get_value(elem),opts)){
            case ~{some}: some;
            case {none}: sel;
          }});
        case ~{section}:
          (s, {section: parse_arguments(prefix ^ selector ^ " ", section)});
      }
    }, defaults);
  }
}
