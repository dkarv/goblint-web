module View {

  client function get_analysis_id(){
    Dom.get_attribute(#tabs, "ana-id");
  }

  client function analysis_finished(ana) {
    Log.debug("view","analysis finished");
    Dom.remove_class(#cfg-tab-parent, "disabled");
    Dom.remove_class(#src-tab-parent, "disabled");

    //Dom.set_attribute_unsafe(link, "href","/analysis/" ^ ana.id)
    Dom.set_attribute_unsafe(#tabs, "ana-id", ana.id)
  }

  // displays the whole page
  function show_root() {
    html = <>
      {Pages.menu()}
      <div class="tab-content" id=#tabs>
        {Xhtml.update_class("active",Pages.uploadtab())}
        {Pages.cfgtab()}
        {Pages.srctab()}
      </div></>
    Resource.page("Goblint", html);
  }

  // DEPRECATED
  function show_analysis(ana){
    html =
      <div id=graphbox>
        <svg onready={function(_) { match(ana.dotfile) {
          case {none}: Log.error("show_analysis", "try to display cfg but not read yet");
          // dotrenderer doesn't understand box, has to be rect -.-
          case {some: dot}: Cfg.render_graph(String.replace("box","rect",dot));
          //case {some: dot}: render_graph(dot);
        }}}/>
      </div>
    Resource.page("Analysis", html)
  }
}
