// different collapse options
type state = {none} or {inout1} or {int loops}

type raw_vertex = {
  string id,
  string shape,
  string label
}

type raw_edge = {
  string start,
  string end,
  string label
}

type raw_graph = {
  list(raw_edge) edges,
  list(raw_vertex) vertices
}

module Graph {
  // transform from raw_edge to graph representation
  // f1 is a list of start nodes
  function (list(string), graph) build(list(raw_edge) edges){
    cnt = List.fold(counter, edges, Map.empty);

    start_nodes = Map.To.key_list(Map.filter(function(_, (in,out)){
      in == 0;
    }, cnt));

    // 1. identify special nodes with (incoming edges != 1 || outgoing edges > 1)
    special_nodes = Map.filter(function(_, (in, out)){
      in != 1 || out > 1;
    }, cnt);

    nodes = List.fold(function(e, acc){
      [e.start | [e.end | acc]];
    }, edges, []);

    // 2. construct map from the edges
    starting_map = List.fold(function(edge, acc){
      new_edge = {a: (edge.start, edge.label), e: edge.end, es: []}
      Multimap.add(edge.start, new_edge, acc);
    }, edges, Multimap.empty);

    is_special = function(string s){
      Map.contains(s, special_nodes);
    }

    result = List.fold(merge(is_special, _, _), nodes, starting_map);

    if(Option.is_some(Cmd.testfile())){
      // debug output
      debug_output = String.concat("\n",
        List.map(print_edges(false,_),
          List.flatten(
            Map.To.val_list(result))));
      Log.debug("Graph", "{debug_output}");

      // do some tests
      if(test1(result)){
        @fail("Graph.Test1 failed");
      }

      if(test2(result, nodes) == false){
        @fail("Graph.Test2 failed");
      }

      Log.debug("Graph.Test", "success!");
    }
    (start_nodes, result);
  }

  recursive function merge((string -> bool) is_special, string node, multimap mm){
    ess = Multimap.get(node, mm);
    // Log.debug("Graph","{node}:");
    List.fold(function(es, mm){
      if(is_special(es.e)){
        // Log.debug("Graph", "can't merge because special: {es.a.f1} -> {es.e}");
        Multimap.add(node, es, mm);
      }else{
        match(extract(es.e, mm)){
          case (_,[]):
            // Log.debug("Graph", "no merge found for e: {es.a.f1} -> {es.e}");
            Multimap.add(node, es, mm);
          case (new_mm,[es2]):
            // Log.debug("Graph", "merge {es.a.f1} -> {es.e} with {es2.a.f1} -> {es2.e}");
            new_es = {a: es.a, e: es2.e, es: es.es ++ [es2.a | es2.es]}
            new_mm = Multimap.add(node, new_es, new_mm);
            // merge again with node, there may be a new possibility
            merge(is_special, node, new_mm)
          default: @fail("more than one merge found for e: {es.a.f1} -> {es.e}");
        };
      }
    }, ess, Multimap.set(node, [], mm));
    // TODO it should be possible to refactor this algorithm to get rid of
    // removing and adding the edges again later
  }

  function print_edges(bool labels, edges e){
    "{e.a.f1}" ^
    if(labels){ "({e.a.f2})" } else { "" } ^
    " -> " ^
    String.of_list(function((e,l)){
      "{e}" ^
      if(labels){ "({l})" } else { "" } ^
      " -> "
    }, "" , e.es) ^ "{e.e}";
  }

  test1 = Map.exists(function(key, vals){
    List.fold(function(e, acc){
      test = e.a.f1 != key;
      if(test == true){
        Log.error("Test","fail: {e}");
      }
      acc || test;
    }, vals, false);
  }, _);

  function test2(result, elist){
    List.fold(function(elem, acc){
      test = Map.exists(function(key, val){
        List.exists(function(e){
          e.a.f1 == elem || e.e == elem ||
          (List.exists(function(e){
            e.f1 == elem;
          }, e.es))
        }, val);
      }, result)
      if(test == false){
        Log.error("Test2","fail: {elem}");
      }
      acc && test;
    }, elist, true)
  }

  function (multimap('a, 'b, 'c), list('b)) extract(key, map){
    (new_map, elem) = Map.extract(key, map);
    new_elem = match(elem){
      case {none}: [];
      case {some: s}: s;
    }
    (new_map, new_elem);
  }

  function list(string) find_posts(list(string) starts, graph g){
    (results, new_starts) = Multimap.fold(function(_, edges e, (res, new_starts)){
      (again, found) = find_post(e, starts);
      if(again){
        (found ++ res, [e.e | new_starts]);
      }else{
        (found ++ res, new_starts);
      }
    }, g, ([],[]));

    new_results = results ++ add_rec(Set.empty, new_starts, g);

    // TODO use a set so no unique is necessary
    List.unique_list_of(new_results);
  }

  function add_rec(added, starts, graph g){
    match(starts){
      case []: []
      case [x | xs]:
        if(Set.contains(x, added)){
          add_rec(added, xs, g);
        }else{
          (new_results, new_starts) = List.fold(function(e, (re, st)){
            ([e.e | map_snd(e.es) ++ re], [e.e | st])
          }, Multimap.get(x,g), ([],[]));
          rec_results = add_rec(Set.add(x, added), new_starts ++ xs, g);
          new_results ++ rec_results;
        }
    }
  }

  function (bool, list(string)) find_post(edges e, starts){
    if(List.contains(e.a.f1, starts)){
      (false, [e.a.f1 , e.e | map_snd(e.es)]);
    } else {
      (b, ls) = find_post_helper(e.es, starts);
      if( b ){ (b, [e.e | ls]) } else { (b, ls) }
    }
  }

  recursive function (bool, list(string)) find_post_helper(es, starts){
    match(es){
      case []: (false, [])
      case [(e,_) | new_es]:
        if(List.contains(e, starts)){
          (true, [e | map_snd(new_es)])
        } else {
          find_post_helper(new_es, starts);
        }
    }
  }

  map_snd = List.map(function((x,_)){ x }, _);

  function list(string) find_pres(list(string) starts, list(string) start_nodes, graph g){
    // create a map: last node -> edges
    reverse_map = Multimap.fold(function(_, edges e, acc1){
      Multimap.add(e.e, e, acc1);
    }, g, Multimap.empty);
    void

    get_reverse = Multimap.get(_, reverse_map);
    get_forward = Multimap.get(_, g);

    // this can be saved for the next search
    predominators = List.fold(iterate(get_forward, get_reverse, _, _), start_nodes, Map.empty);
    Log.debug("Result:","\n{print(predominators)}");

    // search for starts
    (found_starts, found_items) = Multimap.fold(function(key, {e: e, a: (a,l), es: es}, (st, it)){
      st = if(List.contains(e, starts)){
        [e | st];
      }else{ st }
      st = if(List.contains(a, starts)){
        [a | st];
      }else { st }
      match(find_pre(es, starts)){
        case {none}: (st, it);
        case {some: res}: ([a | st],res ++ it)
      }
    }, g, ([],[]));

    Log.debug("found_starts:", "{found_starts}");
    Log.debug("found_items:", "{found_items}");

    extend_these = List.fold(function(x, acc){
      match(Map.get(x, predominators)){
        case {none}: acc
        case {some: s}: Set.union(s, acc);
      }
    }, found_starts, Set.empty);

    Log.debug("extend_these:", "{extend_these}");

    extended_items = Set.fold(function(e, acc){
      match(Multimap.get(e, g)){
        case []: acc
        case [x]: [e | map_snd(x.es) ++ acc]
        case [x, y | xs]: [e | acc]
      }
    }, extend_these, []);

    found_items ++ extended_items;
  }

  private function iterate(get_forward, get_reverse, string current_node, doms){
    Log.debug("##########","\n{current_node}")
    new_doms = calc_new_doms(current_node, doms, get_reverse(current_node));
    match(new_doms){
      case {none}:
        Log.debug("end iterate:", "no change");
        doms;
      case {some: x}:
        // some change happened
        Log.debug("end iterate:","\n{print(x)}");
        List.fold(function(x, acc_doms){
          iterate(get_forward, get_reverse, x.e, acc_doms);
        }, get_forward(current_node), x);
    }
  }

  private function option(list(string)) find_pre(ls, starts){
    match(ls){
      case []: {none}
      case [(x,_) | xs]:
        match(find_pre(xs, starts)){
          case {none}:
            if(List.contains(x, starts)){
              {some: [x]}
            } else {
              {none}
            }
          case {some: s}: {some: [x | s]}
        }
    }
  }

  private function calc_new_doms(current_node, doms, xs){
    // add pre-dominators only if they pre-dominate all x in xs
    // all nodes that target this node without the ones that loop back to the current_node
    without_loops = List.filter_map(function(e){
      x = e.a.f1;
      if(x == current_node){
        {none}
      }else{
        match(Map.get(x, doms)){
          case {none}: {none}
          case {some: s}:
            if(Set.contains(current_node, s)){ {none}
            } else { {some: x} }
        }
      }
    }, xs);

    add_dom = all_equal(without_loops);

    // all predecessors of nodes in query_list
    query_result = List.map(function(x){
      get(x, doms);
    }, without_loops);
    // new predecessors
    new_set = match(query_result){
      case []: Set.empty;
      case [x | xs]: List.fold(Set.intersection, xs, x);
    }
    new_set = match(add_dom){
      case {none}: new_set;
      case {some: d}: Set.add(d, new_set);
    }
    union(current_node, new_set, doms);
  }

  private function all_equal(ls){
    match(ls){
      case []: {none}
      case [x]: {some: x}
      case [x , y | xs]:
        if(x == y){
          all_equal([y | xs]);
        }else{
          {none}
        }
      }
  }

  private function option(map(string, set(string))) add(string key, string value, map(string, set(string)) map){
    match(Map.get(key, map)){
      case {none}:
        {some: Map.add(key, Set.singleton(value), map)};
      case {some: s}:
        if(Set.contains(value, s)){
          {none};
        } else {
          {some: Map.add(key, Set.add(value, s), map)};
        }
    }
  }

  private function option(map(string, set(string))) union(key, set, map){
    match(Map.get(key, map)){
      case {none}: {some: Map.add(key, set, map)};
      case {some: s}:
        both_sets = Set.union(set,s);
        if(Set.equal(both_sets, set)){
          {none}
        }else{
          {some: Map.add(key, both_sets, map)};
        }
    }
  }

  private function set get(string key, map){
    match(Map.get(key, map)){
      case {none}: Set.empty;
      case {some: s}: s;
    }
  }

  private function string print(map){
    String.of_list(function((k, v)){
      val = String.of_list(function(x){ x }, ",", Set.To.list(v))
      k ^ " -> [{val}]"
    }, "\n", Map.To.assoc_list(map));
  }

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

  private function count(option((string, int)) last, ls){
    match((ls,last)){
      case ([],{none}): []
      case ([],{some: x}): [x]
      case ([l | ls],{none}): count({some: (l,1)}, ls)
      case ([l | ls],{some: (old, i)}):
        if(l == old) {
          count({some: (old, i+1)}, ls);
        } else {
          [(old, i) | count({some: (l,1)}, ls)];
        }
    }
  }

  private function filter_map(map,(x, i)){
    Log.debug("Count","{x}: {i}");
    if( List.check_length(Multimap.get(x, map),i)){
      {some: x}
    }else{
      {none}
    }
  }

  private function edges collapse_to_single({a: (a,l), ~e, ~es}){
      lbls = [l | List.map(function((_,l)){ l }, es)];
      lbl = String.concat("\n", lbls);
      {a: (a, lbl), e: e, es: []}
  }

  private function graph collapse_loops(graph g){
    // TODO change g from list to map
    // TODO redo this stuff
    // to support loop collapsing for numbers bigger than 0, we need to remove the edges and not map them to a single one
    /*without_loops = List.map(function(e){
      if(e.e == e.a.f1){
        collapse_to_single(e);
      }else{
        e;
      }
    }, g);
    // now merge two lists A and B iff A is the only one that starts at x and B is the only one that ends at x
    // this is more simple with a map, we need a map
    without_loops;*/
    g;
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