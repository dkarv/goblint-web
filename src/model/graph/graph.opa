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
        cnt = List.fold(help, g.edges, Map.empty);
        rm_verts = List.filter_map(function((id, (in, out))){
          Log.debug("Graph", "{id}: {in},{out}");
          if(in == 1 && out == 1){
            {some: id};
          }else{
            {none}
          }
        }, Map.To.assoc_list(cnt));
        vertices = List.filter(function(vertex){
          Option.is_none(List.index(vertex.id, rm_verts));
        },g.vertices);
        edges = remove_edges(g.edges, rm_verts);
        ~{edges, vertices}
    }
  }

  private function list(edge) remove_edges(list(edge) edges, list(string) vertices){
    List.fold(function(vertex, edges){
      Log.debug("Remove vertex","{vertex}");
      (edges, starts, ends) = List.fold(
        function(edge, (eds, e1, e2)){
          if(edge.end == vertex){
            (eds, [edge | e1], e2);
          }else{
            if(edge.start == vertex){
              (eds, e1, [edge | e2]);
            }else{
              ([edge | eds], e1, e2);
            }
          }
        }, edges, ([],[],[]));
      Log.debug("", "Edges afterwards:");
      List.iter(function(e){
        Log.debug("","{e}");
      }, edges);
      new_edges = List.collect(function(s){
        List.map(function(e){
          {start: s.start, end: e.end, label: s.label ^ "\n" ^ e.label};
        }, ends);
      }, starts);
      Log.debug("", "New edges:");
      List.iter(function(e){
        Log.debug("","{e}");
      }, new_edges);

      (new_edges ++ edges);
    }, vertices, edges);
  }

  private function list(edge) remove_edge(list(edge) edges, string vertex){
    Log.debug("Graph vertex","{vertex}");
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
    Log.debug("Graph starts","{starts}");
    Log.debug("Graph ends","{ends}");
    new_edges = List.collect(function((start, d1)){
      List.map(function((end, d2)){
        {~start, ~end, label: d1 ^ "\n" ^ d2}
      }, ends);
    }, starts);
    Log.debug("Graph","edges: {edges}");
    Log.debug("Graph","new: {new_edges}");
    edges ++ new_edges
  }

  private function stringmap((int, int)) help(v, acc){
    (in, out) = get_default(acc, v.end, (0,0));
    m = Map.add(v.end, (in + 1, out), acc);
    (in, out) = get_default(acc, v.start, (0,0));
    Map.add(v.start, (in, out + 1), m);
  }

  private function 'a get_default(stringmap('a) map, string key, 'a instead){
    match(Map.get(key, map)){
      case {none}: instead;
      case {some: r}: r;
    }
  }
}