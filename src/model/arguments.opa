type arg = {string val} or {int i} or {bool bln} or
  {list(string) opts, int sel} or {list(string) opts, list(int) sels} or
  {list((string,arg)) section}

//type msg = {parse}

module Arguments{

  function list((string, arg)) parse_args(){
    System.exec(Model.goblint ^ " --writeconf conf.json", "");
    string content = Binary.to_string(File.read("conf.json"));
    match(Json.deserialize(content)){
      case ~{some}:
        parse_arg(some);
      case {none}: []
    }
  }

  /* changes the arguments in the second parameter if they are in the first list. */
  recursive function replace_fixed(list((string, arg)) fixed, (string, arg) (s,a)){
    match(List.find(function((str,_)){s == str}, fixed)){
      case {none}: (s,a);
      case {some: (s2,a2)}:
        match(a2){
          case {section: fixed_section}:
            match(a){
              case {section: other_section}:
                (s,{section: List.map(replace_fixed(fixed_section,_),other_section)});
              default: @fail("fixed argument is section {fixed_section}, but the other one not {a}");
            }
          default: (s2, a2);
        }
    };
  }

  recursive function list((string, arg)) parse_arg(RPC.Json.json txt){
    match(txt){
      case {Record: ls}:
        List.map(replace_fixed(fixed,_),
        List.map(function((string, RPC.Json.json) (s,elem)){
          match(elem){
            case {Bool: t}: (s,{bln: t});
            case {String: str}: (s,{val: str});
            case {Int: i}: (s,~{i})
            case {List: ls}:
              (s,{val: "[" ^ String.concat(",", List.map(function(elem){
                match(elem){
                  case {String: s}: s;
                  case {Int: i}: String.of_int(i);
                  default: @fail("unknown list element: {elem}");
                }
              },ls)) ^ "]"} );
            case {Record: r}:
              (s, {section: parse_arg(elem)});
            default:
              @fail("can't parse: {elem}")
          }
        },ls));
      default:
        @fail("unknown value: {txt}");
    }
  }

  Mutable.t(option(list((string, arg)))) global_arg = Mutable.make({none})

  /* arguments necessary for this webinterface. */
  list((string, arg)) fixed = [
    ("outfile", {val: "result.xml"}),
    ("result", {val: "fast_xml"}),
    ("exp", {section: [("cfgdot",{bln: true})]}),
    ("justcfg", {bln: true})
  ]

  function get_defaults(){
    match(global_arg.get()){
      case ~{some}:
        some
      case {none}:
        ls = parse_args();
        global_arg.set({some: ls});
        ls;
    }
  }

  function get_keys(){
    List.map(function((a,b)){a}, get_defaults());
  }

  function xhtml html(list((string, arg)) args){
    List.fold(function(el, acc){
      <>
        {acc}
        {html_arg(fixed, el)}
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

  recursive function xhtml html_arg(list((string, arg)) fixed, (string,arg) (str, a)){
    xhtml label =
      <label class="control-label col-xs-4" for={str}> {str}</label>
    bool disabled =
      List.exists(function((s,a)){ s == str }, fixed);
    label = if(disabled){
      Xhtml.update_class("lock", label);
    }else{
      label;
    }

    function nest(xhtml inner){
      inner = if(disabled){
        <>
          {Xhtml.add_attribute_unsafe("disabled", "true", inner)}
        </>
      }else{ inner }
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
              input = <input type="checkbox" arg-id={str}/>;
              input = if(t){
                Xhtml.add_attribute_unsafe("checked", "true",input)
              }else{ input }
              if(disabled){
                <>
                  {Xhtml.add_attribute_unsafe("disabled", "true", input);}
                </>
              }else{ input }
            }
            <span></span>
          </label>
        </div>)
      case ~{i}:
        nest(Xhtml.update_class("col-xs-7",
          <input type="text" arg-id={str} value={String.of_int(i)} placeholder={String.of_int(i)}/> ))
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
        list((string, arg)) new_fixed =
          match(List.find(function((s, a)){str == s}, fixed)){
            case {some: (s, {section: b})}: b;
            default: [];
          };
        <div arg-id={str} class="panel panel-default">
          <div class="panel-heading collapsed" onclick={showPanel(id,_)} data-toggle={id}>
            <h4 class="panel-title">
              <a>
                {str}
              </a>
            </h4>
          </div>
          <div class="panel-collapse collapse" id={id}>
            <div class="panel-body">
              {
                List.map(html_arg(new_fixed,_),section);
              }
            </div>
          </div>
        </div>
    };
  }

  function string analyzer_call(list((string, arg)) args){
    Log.debug("Arguments","{args}");
    string analyzer = Model.goblint;

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
      case {i: i}: "--set " ^ prefix ^ s ^ " \"" ^ String.of_int(i) ^ "\"";
      case ~{val}:
        string value =
          if(String.is_empty(val)){
            "'" ^ val ^ "'"
          }else{
            if(String.get(0,val) == "["){
              "[" ^ String.concat(",",
                List.map(function(s){"'" ^ s ^ "'"},
                  String.explode(",",
                    String.substring(1,String.length(val) - 2, val)
              ))) ^ "]";
            }else{ "'" ^ val ^ "'" }
          }
        "--set " ^ prefix ^ s ^ " \"" ^ value ^ "\"";
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