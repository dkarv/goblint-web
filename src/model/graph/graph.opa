type state = {none} or {one}

// field e remembers the last element of the list to avoid
// iterating through the whole list only to get the last element
type edgelist = {string e, list(string) ls}

module Graph {
  // transform the list
  function list(edges) build(list(edge) edges){
    Log.debug("Graph","{edges}");
    cnt = List.fold(counter, edges, Map.empty);
    // 1. identify special nodes with (incoming edges != 1 || outgoing edges > 1)
    special_nodes = Map.To.key_list(Map.filter(function(_, (in, out)){
      in != 1 || out > 1
    }, cnt));

    // 2. construct list: List.map(edge -> [edge.start, edge.end], edges)
    working_list = List.map(function(edge){
      {a: (edge.start, edge.label), e: edge.end, es: []}
    }, edges);

    Log.debug("Graph working list", "{working_list}");

    // 3. merge this list like this:
    // [ [A, ..., B], [B, ..., C], ... ] -> [ [A, ..., B, ..., C] ]
    // where
    // B not in special_nodes

    // searches for elements in the second list that can be merged with the first argument
    // if such an element is found, returns {some: the modified list}
    // otherwise {none}
    recursive merge_first = function(edges {a: (a1,l1), e: e1, es: es1} as merge_this, list(edges) es){
      match(es){
        case []: {none}
        case [{a: a2, e: e2, es: es2} as merge_with | es]:
          if(e2 == a1){
            // merge and stop going deeper
            {some: [{e: e1, a: a2, es: (es2 ++ [ (a1,l1) | es1]) } | es]}
          }else{
            // go deeper
            match(merge_first(merge_this, es)){
              case {none}: {none}
              case {some: rlist}:
                {some: [merge_with | rlist]}
            }
          }
      }
    }

    recursive merge_last = function(edges {a: a1, e: e1, es: es1} as merge_this, list(edges) es){
      match(es){
        case []: {none}
        case [{a: (a2,l2), e: e2, es: es2} as merge_with | es]:
          if(a2 == e1){
            // merge and stop going deeper
            {some: [{e: e2, a: a1, es: es1 ++ [(a2, l2) | es2]} | es ]}
          }else{
            match(merge_last(merge_this, es)){
              case {none}: {none}
              case {some: rlist}:
                {some: [merge_with | rlist]}
            }
          }
      }
    }

    recursive merge = function(list(edges) es){
      match(es){
        case []: []
        case [{e: e, a: (a,_), es: _} as edgelist | ess]:
          // [A, ..., B] | [[X, ...,Z], ...]
          if(List.contains(e, special_nodes)){
            // last node is special
            if(List.contains(a, special_nodes)){
              // both first and last node are special, we can't further merge this list
              [edgelist | merge(ess)]
            }else{
              // only the last node is special, try to merge the first one
              match(merge_first(edgelist, ess)){
                case {none}:
                  [edgelist | merge(ess)]
                case {some: new_ess}:
                  merge(new_ess);
              }
            }
          }else{
            // last node isn't special, try to merge this one
            match(merge_last(edgelist, ess)){
              case {some: new_ess}:
                merge(new_ess);
              case {none}:
                // no merge possible for the last, check if possible for the first
                if(List.contains(a, special_nodes)){
                  // can't further merge this edgelist
                  [edgelist | merge(ess)]
                }else{
                  match(merge_first(edgelist, ess)){
                    case {none}:
                      // no merge possible any more
                      [edgelist | merge(ess)]
                    case {some: new_ess}:
                      merge(new_ess);
                  }
                }
            }
          }
      }
    }

    merge(working_list);
  }

  function option(list(string)) find_post(list(string) starts, list((string,string)) searchlist){
    if(List.is_empty(starts)){
      {none}
    }else{
      match(searchlist){
        case []: {none}
        case [(a,_) | bs]:
          if(List.contains(a, starts)){
            {some: [a | List.map(function((x,_)){x},bs)]}
          }else{
            find_post(starts, bs);
          }
      }
    }
  }

  /* returns the found nodes in the wrong direction because of performance issues.
    if you want them in the right direction, reverse the result list */
  function option(list(string)) find_pre(list(string) starts, string last ,list((string,string)) searchlist){
    if(List.is_empty(starts)){
      {none}
    }else{
      match(searchlist){
        case []: if(List.contains(last, starts)){
          {some: [last]}
        }else{
          {none}
        }
        case [(a,_) | bs]:
          match(find_pre(starts, last, bs)){
            case {none}:
              if(List.contains(a, starts)){
                {some: [a]}
              }else{
                {none}
              }
            case {some: s}:
              {some: [a | s]}
          }
      }
    }
  }

  function(list(string), list(string)) find_post_helper(list(string) starts, list(edges) edgess){
    match(edgess){
      case []:
        ([],[])
      case [e | es]:
        (matches, new_starts) = match(find_post(starts, [e.a | e.es])){
          case {none}:
            ([],[])
          case {some: s}:
            // add a new item to the starts list
            // TODO would a insert only if not inside yet improve performance for the starts list?
            ([e.e | s], [e.a.f1])
        }
        (starts_again, recursive_matches) = find_post_helper(new_starts ++ starts, es);

        // maybe there are new possible starts, so search again for them
        (new_matches, all_starts_again) = match(find_post(starts_again, [e.a | e.es])){
          case {none}:
            // we're ready finally, the new starts found no new matches
            ([],new_starts ++ starts_again)
          case {some: s}:
            ([e.e | s], [e.a.f1 | new_starts ++ starts_again])
        }
        (all_starts_again, new_matches ++ matches ++ recursive_matches)
    }

  }

  // returns:
  // (additional starts that should be tested again when
  //  returning from the recursive call,
  //  the nodes that were found in the meantime)
  // post: true if all nodes after one
  function (list(string), list(string)) find_pre_helper(list(string) starts, list(edges) edgess){
    match(edgess){
      case []:
        ([],[])
      case [e | es]:
        (matches, new_starts) = match(find_pre(starts,e.e, [e.a | e.es])){
          case {none}:
            ([],[])
          case {some: s}:
            // add a new item to the starts list
            // TODO would a insert only if not inside yet improve performance for the starts list?
            (s, [e.e])
        }
        (starts_again, recursive_matches) = find_pre_helper(new_starts ++ starts, es);

        // maybe there are new possible starts, so search again for them
        (new_matches, all_starts_again) = match(find_pre(starts_again,e.e, [e.a | e.es])){
          case {none}:
            // we're ready finally, the new starts found no new matches
            ([],new_starts ++ starts_again)
          case {some: s}:
            (s, [e.e | new_starts ++ starts_again])
        }
        (all_starts_again, new_matches ++ matches ++ recursive_matches)
    }
  }

  function list(string) find_posts(list(string) starts, list(edges) edgess){
    find_post_helper(starts, edgess).f2;
  }

  function list(string) find_pres(list(string) starts, list(edges) edgess){
    find_pre_helper(starts, edgess).f2;
  }

  function option(graph) collapse(state st, string id){
    g = Database.get_cfg(id);
    match(g){
      case {none}:
        {none}
      case {some: gr}:
        {some: collapse_graph(gr, st)};
    }
  }

  private function graph collapse_graph(graph g, state st){
    match(st){
      case {none}: g
      case {one}:
        // count the in- and outgoing edges for each vertex
        cnt = List.fold(counter, g.edges, Map.empty);
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

  private function stringmap((int, int)) counter(v, acc){
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