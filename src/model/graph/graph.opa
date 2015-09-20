type state = {none} or {one}
module Graph {
  function option(Model.graph) collapse(state st, string id){
    g = Model.get_cfg(id);
    match(g){
      case {none}:
        {none}
      case {some: gr}:
        {some: collapse_graph(gr, st)};
    }
  }

  private function Model.graph collapse_graph(Model.graph g, state st){
    match(st){
      case {none}: g
      case {one}:
        // count the in- and outgoing edges for each vertex
        cnt = List.fold(help, g.edges, {in: Map.empty, out: Map.empty});
        (vertices, edges) = List.fold(function(test, (verts, edges)){
          if (get_default(cnt.in, test.id, 0) == 1 &&
              get_default(cnt.out, test.id, 0) == 1){
            (verts, remove_edge(edges, test.id))
          } else {
            ([test | verts], edges)
          }
        }, g.vertices, ([], g.edges));
        {edges: edges, vertices: vertices}
    }
  }

  private function list(edge) remove_edge(list(edge) edges, string vertex){
    (edges, starts, ends) = List.fold(
      function(edge, (eds, e1, e2)){
      if(edge.end == vertex){
        (eds, [(edge.start, edge.label) | e1], e2)
      }else{
        if(edge.start == vertex) {
          (eds, e1, [(edge.end, edge.label) | e2])
        }else{
          ([edge | eds], e1, e2)
        }
      }
    }, edges, ([],[],[]));
    Log.debug("Graph","edges\n{starts}\n{ends}");
    new_edges = List.map2(function((start, d1), (end, d2)){
      {~start, ~end, label: d1 ^ "\n" ^ d2}
    }, starts, ends);
    Log.debug("Graph","edges: {edges}");
    Log.debug("Graph","new: {new_edges}");
    edges ++ new_edges
  }

  private function {stringmap(int) in, stringmap(int) out} help(v, acc){
    in = Map.add(v.end, get_default(acc.in, v.end, 0) + 1, acc.in);
    out = Map.add(v.start, get_default(acc.in, v.start, 0) + 1, acc.out);
    Log.debug("Graph","{v}");
    ~{in, out}
  }

  private function int get_default(stringmap(int) map, string key, int instead){
    match(Map.get(key, map)){
      case {none}: instead;
      case {some: r}: r;
    }
  }
}