type state = {none} or {one}

// field e remembers the last element of the list to avoid
// iterating through the whole list only to get the last element
type edgelist = {string e, list(string) ls}

module Graph {
  // transform the list
  function list(edgelist) build(list(edge) edges){
    Log.debug("Graph","{edges}");
    cnt = List.fold(counter, edges, Map.empty);
    // 1. identify special nodes with (incoming edges != 1 || outgoing edges > 1)
    special_nodes = Map.To.key_list(Map.filter(function(_, (in, out)){
      in != 1 || out > 1
    }, cnt));

    // 2. construct list: List.map(edge -> [edge.start, edge.end], edges)
    working_list = List.map(function(edge){
      {e: edge.end, ls: [edge.start, edge.end]};
    }, edges);

    Log.debug("Graph working list", "{working_list}");

    // 3. merge this list like this:
    // [ [A, ..., B], [B, ..., C], ... ] -> [ [A, ..., B, ..., C] ]
    // where
    // B not in special_nodes

    // searches for elements in the second list that can be merged with the first argument
    // if such an element is found, returns {some: the modified list}
    // otherwise {none}
    recursive merge_first = function(string first, string last, list(string) others, list(edgelist) es){
      match(es){
        case []: {none}
        case [a | es]:
          if(a.e == first){
            // merge and stop going deeper
            {some: [{e: last, ls: (a.ls ++ others)} | es]}
          }else{
            // go deeper
            match(merge_first(first, last, others, es)){
              case {none}: {none}
              case {some: rlist}:
                {some: [a | rlist]}
            }
          }
      }
    }

    recursive merge_last = function(string first, string last, list(string) others, list(edgelist) es){
      match(es){
        case []: {none}
        case [{~e, ls: [l | ls]} as a | es]:
          if(l == last){
            // merge and stop going deeper
            {some: [{e: e, ls: [first | others] ++ ls} | es ]}
          }else{
            match(merge_last(first, last, others, es)){
              case {none}: {none}
              case {some: rlist}:
                {some: [a | rlist]}
            }
          }
        default: @fail("this list is not allowed to be empty");
      }
    }

    recursive merge = function(list(edgelist) edges){
      match(edges){
        case [{e: last,ls: [first | ls]} as es | ess]:
          // [A, ..., B] | [[X, ...,Z], ...]
          if(List.contains(last, special_nodes)){
            if(List.contains(first, special_nodes)){
              // both first and last node are special, we can't further merge this list
              [es | merge(ess)]
            }else{
              // only the last node is special, try to merge the first one
              match(merge_first(first, last, ls, ess)){
                case {none}:
                  // no merge possible any more
                  [es | merge(ess)]
                case {some: new_ess}:
                  merge(new_ess);
              }
            }
          }else{
            // last node isn't special, try to merge this one
            match(merge_last(first, last, ls, ess)){
              case {some: new_ess}:
                merge(new_ess);
              case {none}:
                // no merge possible for the last, check if possible for the first
                if(List.contains(first, special_nodes)){
                  // can't further merge this
                  [es | merge(ess)]
                }else{
                  match(merge_first(first, last, ls, ess)){
                    case {none}:
                      // no merge possible any more
                      [es | merge(ess)]
                    case {some: new_ess}:
                      merge(new_ess);
                  }
                }
            }
          }
        case []: []
        default: @fail("not allowed: {edges}")
      }
    }

    merge(working_list);
  }

  function option(list(string)) find_post(list(string) starts, list(string) searchlist){
    if(List.is_empty(starts)){
      {none}
    }else{
      match(searchlist){
        case []: {none}
        case [a | bs]:
          if(List.contains(a, starts)){
            {some: [a | bs]}
          }else{
            find_post(starts, bs);
          }
      }
    }
  }

  /* returns the found nodes in the wrong direction because of performance issues.
    if you want the right direction, reverse the result list */
  function option(list(string)) find_pre(list(string) starts, list(string) searchlist){
    if(List.is_empty(starts)){
      {none}
    }else{
      match(searchlist){
        case []: {none}
        case [a | bs]:
          match(find_pre(starts, bs)){
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

  // returns:
  // (additional starts that should be tested again when
  //  returning from the recursive call,
  //  the nodes that were found in the meantime)
  function (list(string), list(string)) find_helper(find_function, get_start, list(string) starts, list(edgelist) nodes){
    match(nodes){
      case []:
        ([],[])
      case [n | ns]:
        (matches, new_starts) = match(find_function(starts, n.ls)){
          case {none}:
            ([],[])
          case {some: s}:
            // add the last item to the starts list
            // TODO would a insert only if not inside yet improve performance for the starts list?
            (s, [get_start(n)])
        }
        (starts_again, recursive_matches) = find_helper(find_function, get_start, new_starts ++ starts, ns);

        // maybe there are new possible starts, so search again for them
        (new_matches, all_starts_again) = match(find_function(starts_again, n.ls)){
          case {none}:
            // we're ready finally, the new starts found no new matches
            ([],new_starts ++ starts_again)
          case {some: s}:
            (s, [get_start(n) | new_starts ++ starts_again])
        }
        (all_starts_again, new_matches ++ matches ++ recursive_matches)
    }
  }

  function list(string) find_posts(list(string) starts, list(edgelist) nodes){
    find_helper(find_post,function(n){
      n.e
    }, starts, nodes).f2;
  }

  function list(string) find_pres(list(string) starts, list(edgelist) nodes){
    find_helper(find_pre,function(n){
      match(n.ls){
        case []: @fail("this list is never empty");
        case [l | _]: l
      }
    }, starts, nodes).f2
  }

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