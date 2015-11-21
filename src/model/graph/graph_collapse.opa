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
      case {loops: x}:
        if(x == 0){
          collapse_loops(g);
        } else {
          if(x > 0) {
            // TODO merge the edges
            collapse_graph(remove_loops(g), {loops: x-1});
          } else {
            @fail("Can't use loop with negative number!");
          }
        }
    }
  }

  private function edges collapse_to_single({a: (a,l), ~e, ~es}){
      lbls = [l | List.map(function((_,l)){ l }, es)];
      lbl = String.concat("\n", lbls);
      {a: (a, lbl), e: e, es: []}
  }

  private function graph collapse_loops(graph g){
    Map.map(function(val){
      List.map(function(x){
        if(x.e == x.a.f1){
          collapse_to_single(x);
        } else {
          x
        }
      }, val);
    }, g);
  }
  /**
   * remove loops instead of collapsing
   */
  private function graph remove_loops(graph g){
    Map.map(function(val){
      List.filter(function(x){
        x.e != x.a.f1
      }, val);
    }, g);
  }
}