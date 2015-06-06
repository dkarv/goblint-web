module Pages {
  // returns the html for the nav tabs
  function menu(){
    <ul class="nav nav-tabs">
      <li data-target="#upload">
        <a id=#upload-tab data-target="#upload" onclick={function (_) Tab.show(#upload-tab)}>Upload</a></li>
      <li class="disabled" id=#cfg-tab-parent>
        <a id=#cfg-tab data-target="#cfg" onclick={Cfg.show_cfg}>CFG</a>
      </li>
      <li class="disabled" id=#src-tab-parent data-target="#src">
        <a id=#src-tab data-target="#src" onclick={Src.show_src}>Source</a>
      </li>
    </ul>
  }

  function uploadtab(){
    Upload.config default_config = Upload.default_config();
    form_body =
      <input type="file" name="filename"/>
      <input type="hidden" name="form_id" value="default"/>
      <input type="submit" value="Upload" onclick={function(_) Dom.add_class( #cfg-tab-parent, "disabled")}/>

    Upload.config my_config = {
      {default_config with form_body: form_body} with process:
        Model.upload_analysis(View.analysis_finished,_)
      }
    <div class="tab-pane" id="upload">
      {Upload.html(my_config)}
    </div>
  }

  function srctab(){
    <div class="tab-pane" id=#src>
      <div id=#loc-container>
      </div>
      <pre class="prettyprint linenums" id=#src-container>
      </pre>
    </div>
  }

  function cfgtab(){
    <div class="tab-pane" id=#cfg>
      <div id=#cfg-container>
        <svg></svg>
      </div>
    </div>
  }


}