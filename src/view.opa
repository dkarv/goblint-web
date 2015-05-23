module View {


  function upload(){
    Upload.config default_config = Upload.default_config();
    form_body =
      <input type="file" name="filename"/>
      <input type="hidden" name="form_id" value="default"/>
      <input type="submit" value="Upload"/>

    Upload.config my_config = {
      {default_config with form_body: form_body} with process:
        Model.upload_analysis(analysis_finished,_)
    }
    Upload.html(my_config);
  }

  client function analysis_finished(ana) {
    Log.error("view","analysis finished");
    elem = #ana-tab-parent
    Dom.remove_class(elem, "disabled")
    link = #ana-tab
    Dom.set_attribute_unsafe(link, "href","/analysis/" ^ ana.id)
  }

  function show_root() {
    html = <ul class="nav nav-tabs">
      <li class="active"><a id=#upload-tab href="#upload" onclick={function (_) Tab.show(#upload-tab)}>Upload</a></li>
      <li class="disabled" id=#ana-tab-parent><a id=#ana-tab href="#ana">Analysis</a></li>
    </ul>
    <div class="tab-content">
      <div class="tab-pane active" id="upload">... Upload ...
        {upload()}
      </div>
      <div class="tab-pane" id="analysis">... Analysis ...
      </div>
    </div>
    Resource.styled_page("Upload", ["/resources/css/layout.css"], html);
  }

  function show_analysis(ana){
    html =
      <div id=graphbox>
        <svg onready={function(_) { match(ana.dotfile) {
          case {none}: Log.error("show_analysis", "try to display cfg but not read yet");
          // dotrenderer doesn't understand box, has to be rect -.-
          case {some: dot}: render_graph(String.replace("box","rect",dot));
          //case {some: dot}: render_graph(dot);
        }}}/>
      </div>
    Resource.page("Analysis", html)
  }

  private render_graph = %%DotRenderer.render%%
}
