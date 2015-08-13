type tab = {upload} or {src} or {cfg}

module Pages {

  // returns the html for the nav tabs
  function menu(tab active, list(tab) display, list(tab) disabled){
    <ul class="nav nav-tabs">
      { List.map(function(el){
          list(string) classes = if(el == active){ ["active"] } else {[]};
          classes = if(List.mem(el, disabled)){ ["disabled" | classes] } else {classes}
          List.fold(Xhtml.update_class, classes, produce_menu(el))
        }, display);
      }
      <li class="dropdown pull-right">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button">
          Goblint Arguments <span class="caret"></span>
        </a>
        <form class="dropdown-menu form-horizontal row" id=#arguments>
            {Arguments.html(Arguments.get_defaults())}
        </form>
      </li>
    </ul>
  }

  function tabs(tab active, list(tab) display){
    <div class="tab-content" id=#tabs>
      { List.map(function(el){
          if (el == active){
            Xhtml.update_class("active",produce_tab(el))
          }else{
            produce_tab(el)
          }
        }, display)
      }
    </div>
  }

  function produce_menu(tab t){
    match(t) {
    case {upload}:
      <li data-target="#upload">
        <a id=#upload-tab data-target="#upload"
          onclick={function (_) Tab.show(#upload-tab)}>Upload</a>
      </li>
    case {cfg}:
      <li id=#cfg-tab-parent>
        <a id=#cfg-tab data-target="#cfg"
          onclick={function(_) { Cfg.show()}}
          onready={function(_) {
            if( Dom.has_class( #cfg-tab-parent, "active")){
              Cfg.show()
            }
          }}
        >CFG</a>
      </li>
    case {src}:
      <li id=#src-tab-parent data-target="#src">
        <a id=#src-tab data-target="#src"
          onclick={function(_) {Src.show()}}
          onready={function(_) {
            if( Dom.has_class( #src-tab-parent, "active")){
              Src.show()
            }
          }}
        >Source</a>
      </li>
    }
  }

  function produce_tab(tab t){
    match(t){
    case {upload}:
      Upload.config default_config = Upload.default_config();
      form_body =
        <div class="btn-group">
          <input type="file" name="filename" class="btn btn-default"/>
          <input type="submit" value="Upload" class="btn btn-primary"
            onclick={function(_){
              Dom.add_class( #cfg-tab-parent, "disabled");
              Dom.add_class( #src-tab-parent, "disabled");
            }}/>
        </div>

      Upload.config my_config = {
        {default_config with form_body: form_body} with process: function(res) {
          Model.upload_analysis(View.analysis_finished,View.parse_arguments("",Arguments.get_defaults()),res);
        }
      }
      <div class="tab-pane" id="upload">
        <h4>Upload a file: </h4>
        {Upload.html(my_config)}
        {
          if(Model.args.localmode){
            <>
              <h4>Select local file:</h4>
              {LocalFile.html()}
            </>
          }else{
            <></>
          }
        }
      </div>
    case {src}:
      <div class="tab-pane" id=#src>
        <div id=#loc-container>
        </div>
        <pre class="prettyprint linenums" id=#src-container>
        </pre>
      </div>
    case {cfg}:
      <div class="tab-pane" id=#cfg>
        <div id=#loc-container2>
        </div>
        <div id=#cfg-container>
          <input type="text" class="form-control"
            id=#search_cfg onchange={Cfg.search_change}
            placeholder="regex search for edges"/>
          <svg><g></g></svg>
        </div>
      </div>
    }
  }
}