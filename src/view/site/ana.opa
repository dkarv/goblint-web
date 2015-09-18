module Ana{

  client function xhtml print_analysis(list(analysis) ana){
    <>
      {List.map(map_ana, ana)}
    </>;
  }

  private client function xhtml map_ana(analysis an){
    <>
      <h5>{an.name}:</h5>
      {print_value(an.val)}
    </>
  }

  private client function xhtml print_value(value val){
    match(val){
      case ~{map}:
        <ul>
          {List.fold(fold_it,
            Map.To.assoc_list(
              Map.map(print_value, map)),
                <></>)}
        </ul>
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
    <>
      {acc}
      <li>{key}: -> {val}</li>
    </>
  }
}