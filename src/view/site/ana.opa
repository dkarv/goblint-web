module Ana{

  client function xhtml print_analysis(list(analysis) ana){
    <>
      {List.map(map_ana, ana)}
    </>;
  }

  private client function xhtml map_ana(analysis an){
    id = Dom.fresh_id();
    body = print_value(an.val);
    createPanel(id, an.name, body, false);
  }

  private client function xhtml print_value(value val){
    match(val){
      case ~{map}:
        <>
          {List.fold(fold_it,
            Map.To.assoc_list(
              Map.map(print_value, map)),
                <></>)}
        </>
      case ~{set}:
        <ul>{List.fold(fold_list, set, <></>)}</ul>
      case ~{data}:
        <span>{data}</span>
    }
  }

  private client function xhtml fold_list(value el, xhtml acc){
    <>
      {acc}
      <li>{print_value(el)}</li>
    </>
  }

  private client function xhtml fold_it((string key,xhtml val), xhtml acc){
    id = Dom.fresh_id();
    <>
      {acc}
      {createPanel(id, key, val, true)}
    </>
  }

  private client function xhtml createPanel(string id, string title, xhtml body, bool collapsed){
    (c1, c2) = if(collapsed){ ("collapsed", "")}else{("", "in")};
    <div class="panel panel-default">
      <div class="panel-heading {c1}" onclick={showPanel(id,_)} data-toggle={id}>
        <h5 class="panel-title">
          {title}
        </h5>
      </div>
      <div class="panel-collapse collapse {c2}" id={id}>
        <div class="panel-body">
          {body}
        </div>
      </div>
    </div>
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
}