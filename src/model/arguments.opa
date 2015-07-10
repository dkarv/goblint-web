type arg = {string val} or {string str} or {bool bln}
module Arguments{
  // a list of (option name, default value)
  list((string, arg)) args = [
    ("analyzer", {str: "../analyzer/goblint"}),
    ("dopartial", {bln: false}),
    ("noverify", {bln: false}),
    ("exp.cfgdot", {bln: false})
  ];

  /* arguments necessary for this webinterface. */
  list((string, arg)) fixed = [
    ("outfile", {str: "result.xml"}),
    ("result", {str: "fast_xml"}),
    ("justcfg", {bln: true})
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

  function xhtml html_arg((string,arg) (str, a)){
    xhtml label =
      <label class="control-label col-xs-2" for={str}> {str}</label>

    xhtml h =
      match(a){
        case {bln: t}:
          <div class="checkbox-slider--a-rounded checkbox-slider-md col-xs-9">
            <label>
              {
              if (t){
                <input type="checkbox" id={str} checked/>
              } else {
                <input type="checkbox" id={str}/>
              }}
              <span></span>
            </label>
          </div>
        case {str: s}:
          Xhtml.add_id({some: str},
          Xhtml.update_class("col-xs-9",
          Xhtml.update_class("form-control",
            <input type="text" value={s}/> )));
        case {val: s}:
          Xhtml.add_id({some: str},
          Xhtml.update_class("col-xs-9",
          Xhtml.update_class("form-control",
            <input type="text" value={s}/> )));
      };

    <>
      <div class="form-group">
        {label}
        {h}
      </div>
    </>
  }

  function string analyzer_call(list((string, arg)) args){
    Log.debug("Arguments","{args}");
    string analyzer = match(Option.get(List.assoc("analyzer", args))){
      case ~{str}: str;
      default: @fail("nonsense");
    }
    args = List.remove(("analyzer", {str: analyzer}), args) ++ fixed;

    string arguments = String.concat(" ", List.map(print_arg, args));

    Log.debug("Arguments",arguments);

    analyzer ^ " " ^ arguments;
  }

  function string print_arg((string,arg) a){
    match(a){
      case (s, {bln: {true}}): "--enable " ^ s;
      case (s, {bln: {false}}): "--disable " ^ s;
      case (s, ~{str}): "--sets " ^ s ^ " " ^ str;
      case (s, ~{val}): "--set " ^ s ^ " " ^ val;
    }
  }
}