type tab = {upload} or {src} or {cfg}

module Pages {

  function string name(tab t){
    match(t){
      case {upload}: "Upload";
      case {src}: "Source"
      case {cfg}: "Graph"
    }
  }

  // returns the html for the nav tabs
  function menu(tab active, list(tab) display, list(tab) disabled){
    <>
        <div class="header">
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
                      file_path = Model.get_file_path(id);
                      Model.rerun_analysis(
                        Site.analysis_finished, id,
                        ViewArguments.to_arguments("",
                          ViewArguments.get_defaults({some: file_path})));
                  }
                }
                }}>
                {ViewArguments.to_html(ViewArguments.get_defaults({none}))}
              </form>
            </li>
          </ul>
        </div>
        <div class="header2">
         <div class="alert" id=#message style="display: none">
          <a class="close" onclick= {function(_){
            Dom.set_style_property_unsafe(#message, "display", "none");}}
          >&times;</a>
          <div id=message-content></div>
        </div>
      </div>
      </>
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
          onclick={function (_){
            Tab.show(#upload-tab);
            %%Util.pushState%%("/");
          }}>Upload</a>
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
        <div class="input-group">
          <input type="file" name="filename" class="form-control"/>
          <span class="input-group-btn">
            <input type="submit" value="Upload" class="btn btn-primary"
              onclick={function(_){
                Dom.add_class( #cfg-tab-parent, "disabled");
                Dom.add_class( #src-tab-parent, "disabled");
              }}/>
          </span>
        </div>

      Upload.config my_config = {
        {default_config with form_body: form_body} with process: function(res) {
          Model.upload_analysis(
            Site.analysis_finished,
            ViewArguments.to_arguments("",ViewArguments.get_defaults({none})),res);
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
      <div class="tab-pane box" id=#src>
        <div id=#loc-container class="left">
          &nbsp;
        </div>
        <div class="right">
          <pre class="prettyprint linenums" id=#src-container></pre>
        </div>
      </div>
    case {cfg}:
      <div class="tab-pane box" id=#cfg>
        <div id=#loc2-container class="left">
          &nbsp;
        </div>
        <div id=#cfg-container class="right">
          <select id=#collapse-sel onchange={Cfg.collapse_change} class="form-control">
            <option value="none">Don't collapse</option>
            <option value="one">Simple collapse</option>
          </select>
          <div class="input-group">
            <input type="text" class="form-control"
              id=#search_cfg onchange={Cfg.search_change}
              placeholder="search for edges"/>
            <span class="input-group-btn">
              <div class="btn btn-primary" onclick={function(_){
                if(Dom.has_class(#search-help, "visible")){
                  Dom.set_style_property_unsafe(#search-help, "display", "none");
                  Dom.remove_class(#search-help, "visible");
                }else{
                  Dom.set_style_property_unsafe(#search-help, "display", "block");
                  Dom.add_class(#search-help, "visible");
                }
              }}>?</div>
            </span>
          </div>
          <div id=#search-help style="display: none;">
            <h4>Compare variable x with values:</h4>
            <table>
              <tr>
                <td>x=string</td><td>var x has exact value string</td>
              </tr>
              <tr>
                <td>x=int</td><td>x has exact value int</td>
              </tr>
              <tr>
                <td>x&lt;int</td><td>x smaller than int</td>
              </tr>
              <tr>
                <td>x&gt;int</td><td>x bigger than int</td>
              </tr>
              <tr>
                <td>x[int_1;int_2]</td><td>x &gt;= int_1 and x &lt;=int_2</td>
              </tr>
            </table>
            <h4>Combine the rules above:</h4>
            <table>
              <tr>
                <td>expr_1|expr_2</td><td>expr_1 OR expr_2</td>
              </tr>
              <tr>
                <td>expr_1&expr_2</td><td>expr_1 AND expr_2</td>
              </tr>
              <tr>
                <td>(expr)</td><td>Change the precedence of expressions</td>
              </tr>
              <tr>
                <td>!expr</td><td>Negate the expr</td>
              </tr>
            </table>
          </div>
            <svg class="cfg"><g></g></svg>
            <div id=#description></div>
          </div>
      </div>
    }
  }
}