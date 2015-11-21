// different collapse options
type state = {none} or {inout1} or {int loops}

module GraphCollapse {
  function graph collapse(state st, string id){
    g = Database.get_cfg(id);
    collapse_graph(g, st);
  }

  private function graph collapse_graph(graph g, state st){
    match(st){
      case {none}: g
      case {inout1}:
        Map.map(List.map(collapse_to_single, _), g);
      case {loops: x}: g
        // TODO fix this
        /*if(x == 0){
          collapse_loops(g);
        }else{
          collapse_loops(collapse_graph(g, {loops: x - 1}));
        }*/
    }
  }
}