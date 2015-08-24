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
        <form class="dropdown-menu form-horizontal row" id=#arguments onchange={ function(_){
          dom child = Dom.select_id("upload-tab");
          dom parent = Dom.select_parent_one(child);
          isActive = Dom.has_class(parent, "active");
          if(isActive == {false}){
            // the user is on the cfg or src tab currently, so do a live update
            match(Site.get_analysis_id()){
              case {none}:
                Log.error("Pages","can't do live update because there is no ana id");
              case {some: id}:
                Site.show_spinner();
                Model.rerun_analysis(
                  Site.analysis_finished, id,
                  ViewArguments.to_arguments("",ViewArguments.get_defaults()));
            }
          }
        }}>
            {ViewArguments.to_html(ViewArguments.get_defaults())}
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
          Model.upload_analysis(Site.analysis_finished,ViewArguments.to_arguments("",ViewArguments.get_defaults()),res);
        }
      }
      <div class="tab-pane" id="upload">
        <h4>Upload a file: </h4>
        {Upload.html(my_config)}
        {
          if(Cmd.localmode()){
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
        <div id=#loc2-container>
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