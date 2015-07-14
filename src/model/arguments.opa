type arg = {string val} or {string str} or {bool bln} or
  {list(string) opts, int sel} or {list(string) opts, list(int) sels} or
  {list((string,arg)) section}

module Arguments{
  function (string,arg) t(string s){
    (s, {bln: true})
  }

  function (string,arg) f(string s){
    (s,{bln: false})
  }

  function (string,arg) st(string s, string v){
    {(s, {str: v})}
  }

  function (string,arg) vl(string s, string v){
    (s, {val: v})
  }

  function (string,arg) op(string s, list(string) o, int i){
    (s, {opts: o, sel: i})
  }

  function (string,arg) ops(string s, list(string) o, list(int) i){
    (s, {opts: o, sels: i})
  }

  function (string, arg) sc(string s, list((string, arg)) a){
    (s, {section: a})
  }

  // a list of (option name, default value)
  // TODO generate from goblint defaultconf goblint --writeconf file.json
  list((string, arg)) args = [
    st("analyzer","../analyzer/goblint"),
    vl("includes","[]"),
    vl("kernel_includes","[]"),
    vl("custom_includes","[]"),
    vl("custom_incl",""),
    f("custom_libc"),
    f("dopartial"),
    f("gccwarn"),
    f("noverify"),
    vl("mainfun","['main']"),
    vl("exitfun","[]"),
    vl("otherfun","[]"),
    f("allglobs"),
    f("keepcpp"),
    t("merge-conflicts"),
    vl("cppflags",""),
    f("kernel"),
    f("dump_globs"),
    op("solver", ["effectWCon"],0),
    op("comparesolver", ["effectWCon", " "],1),
    f("solverdiffs"),
    f("allfuns"),
    f("nonstatic"),
    f("colors"),
    f("g2html"),
    sc("interact",[
      st("out","result"),
      f("enabled"),
      f("paused")]),
    vl("phases","[]"),
    sc("ana", [
      ops("activated",["base","escape","mutex"],[0,1,2]),
      ops("path_sens",["OSEK","OSEK2","mutex","depmutex","malloc_null","uninit"],[0,1,2,3,4,5]),
      ops("ctx_insens",["OSEK2","stack_loc","stack_trace_set"],[0,1,2]),
      f("warnings"),
      sc("cont", [
        f("localclass"),
        st("class","")]),
      sc("osek",[
        st("oil",""),
        t("defaults"),
        st("isrprefix","function_of_"),
        st("taskprefix","function_of_"),
        st("isrsuffix",""),
        st("tasksuffix",""),
        f("intrpts"),
        f("check"),
        vl("names","[]"),
        f("warnfiles"),
        vl("safe_vars","[]"),
        vl("safe_task","[]"),
        vl("safe_isr","[]"),
        vl("flags","[]"),
        t("def_header")]),
      sc("int",[
        t("trier"),
        f("interval"),
        f("cinterval"),
        f("cdebug"),
        op("cwiden",["basic","double"],0),
        op("cnarrow",["basic","half"],0)]),
      f("file.optimistic"),
      st("spec.file",""),
      sc("arinc",[
        t("assume_success"),
        t("simplify"),
        t("validate"),
        t("export"),
        t("debug_pml"),
        t("merge_globals")]),
      t("hashcons"),
      st("restart_count","1")])
  ];

  /* arguments necessary for this webinterface. */
  list((string, arg)) fixed = [
    st("outfile", "result.xml"),
    st("result", "fast_xml"),
    t("justcfg")
  ]

  function get_defaults(){
    args;
  }

  function get_keys(){
    List.map(function((a,b)){a}, get_defaults());
  }

  function xhtml html(list((string, arg)) args){
    List.fold(function(el, acc){
      <>
        {acc}
        {html_arg(el)}
      </>
    }, args, <></>);
  }

  function showPanel(id, _){
    elem = Dom.select_id(id);
    trigger = Dom.select_raw_unsafe("[data-toggle='" + id + "']");
    if(Dom.has_class(elem, "in")){
      Dom.remove_class(elem, "in");
      Dom.add_class(trigger, "collapsed");
    }else {
      Dom.add_class(elem, "in");
      Dom.remove_class(trigger, "collapsed");
    }
  }

  recursive function xhtml html_arg((string,arg) (str, a)){
    xhtml label =
      <label class="control-label col-xs-4" for={str}> {str}</label>

    function nest(xhtml inner){
      <div class="form-group">
        {label}
        {inner}
      </div>
    }

      match(a){
        case {bln: t}:
          nest(<div class="checkbox-slider--a-rounded checkbox-slider-xs col-xs-2">
            <label>
              {
              if (t){
                <input type="checkbox" arg-id={str} checked/>
              } else {
                <input type="checkbox" arg-id={str}/>
              }}
              <span></span>
            </label>
          </div>)
        case {str: s}:
          nest(Xhtml.update_class("col-xs-7",
            <input type="text" arg-id={str} value={s} placeholder={s}/> ))
        case {val: s}:
          nest(Xhtml.update_class("col-xs-7",
            <input type="text" arg-id={str} value={s} placeholder={s}/> ))
        case ~{opts, sels}:
          nest(<select multiple arg-id={str}>
            {List.mapi(function(i, a){
              if (List.mem(i, sels)){
                <option selected value={a}>{a}</option>
              }else{
                <option value={a}>{a}</option>
              }},opts)
            }
          </select>)
        case ~{opts, sel}:
          nest(<select arg-id={str}>
            {List.mapi(function(i, a){
              if (i == sel){
                <option selected value={a}>{a}</option>
              }else{
                <option value={a}>{a}</option>
              }},opts)
            }
          </select>)
        case ~{section}:
          id = Dom.fresh_id();
          <div arg-id={str} class="panel panel-default">
            <div class="panel-heading" onclick={showPanel(id,_)} data-toggle={id}>
              <h4 class="panel-title">
                <a>
                  {str}
                </a>
              </h4>
            </div>
            <div class="panel-collapse collapse" id={id}>
              <div class="panel-body">
                {List.map(html_arg,section)}
              </div>
            </div>
          </div>
      };
  }

  function string analyzer_call(list((string, arg)) args){
    Log.debug("Arguments","{args}");
    string analyzer = match(Option.get(List.assoc("analyzer", args))){
      case ~{str}: str;
      default: @fail("nonsense");
    }
    args = List.remove(("analyzer", {str: analyzer}), args) ++ fixed;

    string arguments =
      String.concat(" ",
        List.map(print_arg("",_),args));
          //List.map(function((s,a)){([s],a)},args)));

    Log.debug("Arguments",arguments);

    analyzer ^ " " ^ arguments;
  }

  function string print_arg(string prefix,(string,arg) (s, a)){
    match(a){
      case {bln: {true}}: "--enable " ^ prefix ^ s;
      case {bln: {false}}: "--disable " ^ prefix ^ s;
      case ~{str}: "--sets " ^ prefix ^ s ^ " " ^ str;
      case ~{val}: "--set " ^ prefix ^ s ^ " \"" ^ val ^ "\"";
      case ~{opts,sels}: "--set " ^ prefix ^ s ^ " \"[" ^ print_opt(opts, sels) ^ "]\"";
      case ~{opts, sel}: "--sets " ^ prefix ^ s ^ " \"'" ^ print_opt(opts, [sel]) ^ "'\"";
      case ~{section}:
        String.concat(" ",
          List.map(function(ar){ print_arg(prefix ^ s ^ ".", ar)}, section));
    }
  }

  function string print_opt(list(string) opts, list(int) sels){
      String.concat(",",
        List.map(function(s){"'" ^ s ^ "'" },
          List.filteri(function(i, s){List.mem(i,sels)},opts)));
  }
}