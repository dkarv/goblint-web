module ViewArguments{
  function xhtml to_html(list((string, arg)) args){
    List.fold(function(el, acc){
      <>
        {acc}
        {html_arg(Arguments.fixed, el)}
      </>
    }, args, <></>);
  }

  get_defaults = Arguments.get_defaults;

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
        nest(
          <div class="checkbox-slider--a-rounded checkbox-slider-xs col-xs-2">
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

  /** triggered when the user clicks on a panel (a collapsable section)*/
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

/** parse the arguments the user selected in the dropdown at the right top */
  client function list((string, arg)) to_arguments(string prefix, list((string, arg)) defaults){
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
          (s, {section: to_arguments(prefix ^ selector ^ " ", section)});
      }
    }, defaults);
  }
}