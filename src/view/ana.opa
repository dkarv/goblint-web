module Ana{
  client function print_analysis(ana){
    <>
      {List.map(function(an){
        <>
          <h5>{an.name}:</h5>
          {print_value(an.val)}
        </>},
      ana)}
    </>;
  }

  client function xhtml print_value(val){
    match(val){
    case ~{map}:
      <ul>{List.fold(function((key,val), acc){
          <>
            {acc}
            <li>{key}: -> {val}</li>
          </>
        },
        Map.To.assoc_list(Map.map(print_value, map)), <></>)}</ul>
    case ~{set}:
      <ul>{List.fold(function(el, acc){
        <>
          {acc}
          <li>{print_value(el)}</li>
        </>},set, <></>)}</ul>
    case ~{data}:
      <span>{data}</span>
    }
  }
}