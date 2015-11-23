type unop = {not_} or {pre_} or {post_}
type binop = {and_} or {or_}
type comp = {eq_}
type icomp = {gt_} or {lt_}
type vcomp = {in_}
type expr =
  /** var == value */
  {string var, string val, comp cmp} or
  {string var, int dec, icomp icmp} or
  {string var, int d1, int d2, vcomp vcmp} or
  /** just a list of node ids  */
  {list(string) nodes} or
  {unreachables} or
  /** this | that */
  {expr e1, expr e2, binop bi} or
  /** !(not), >(nodes), <(nodes)*/
  {expr e, unop un}


/** allows you to search on a graph */
module Search {
  exposed function list(string) search(string id, expr query){
    // Log.debug("Search","starting search");
    stringmap(call) calls = Database.get_id_map(id);
    list(string) nodes = Database.get_call_ids(id);
    // wtf: this void is necessary for the compiler...
    void

    recursive function list(string) inner(expr query){
      match(query){
        // just a list of nodes: {1,2,3}
        case {nodes: nds}:
          List.filter(function(n){
            List.contains(n, nodes);
          }, nds);
        // {dead}: all unreachable nodes
        case {unreachables}:
          Database.get_unreachables(id);
        // negation: !(...)
        case {e: e, un: {not_}}:
          list(string) res_e = inner(e);
          List.filter(function(el){
            if(List.mem(el, res_e ++ Database.get_unreachables(id))){
              false
            }else{
              true
            };
          }, nodes);
        case {e: e, un: {post_}}:
          Graph.find_posts(inner(e), Database.get_cfg(id));
        case {e: e, un: {pre_}}:
          Graph.find_pres(inner(e), Database.get_start_nodes(id), Database.get_cfg(id));
        // AND: e1 & e2
        case {~e1, ~e2, bi: {and_}}:
          list(string) res_e1 = inner(e1);
          list(string) res_e2 = inner(e2);
          List.filter(function(el){
            List.mem(el, res_e1);
          }, res_e2);
        // OR: e1 & e2
        case {~e1, ~e2, bi: {or_}}:
          list(string) res_e1 = inner(e1);
          list(string) res_e2 = inner(e2);
          res_e1 ++ res_e2;
        case {var: searchVar, val: searchValue, ~cmp}:
          f = match(cmp){
            case {eq_}: String.eq(searchValue, _)
          }
          satisfies(f, searchVar, calls);
        case {var: searchVar, dec: searchValue, ~icmp}:
          f = match(icmp){
            case {gt_}: function(i1){
              i1 > searchValue
            }
            case {lt_}: function(i1){
              i1 < searchValue
            }
          }
          void
          satisfies_int(f, searchVar, calls)
        case {var: searchVar, ~d1, ~d2, vcmp: {in_}}:
          satisfies_int(function(i){
            i >= d1 && i <= d2;
          }, searchVar, calls);
      }
    };
    inner(query);
  }

  private function list(string) satisfies_int((int -> bool) f, string searchVar, stringmap(call) calls){
    satisfies(function(s){
      match(Int.of_string_opt(s)){
        case {none}: false;
        case {some: i}:
          f(i)
      }
    },searchVar, calls)
  }

  private function list(string) satisfies((string -> bool) f, string searchVar, stringmap(call) calls){
    // TODO maybe it's also possible to do this in database queries
    Map.fold(function(key, val, acc){
      List.fold(function((_, paths), acc){
        List.fold(function(ana, acc){
          if(String.eq("base", ana.name)){
            if(satisfies_helper(f, searchVar, ana.val)){
              [key | acc];
            } else {
              acc;
            }
          } else {
            acc;
          }
        }, paths, acc);
      }, val.anas, acc);
    }, calls, []);
  }

  private function bool satisfies_helper((string -> bool) f, string searchVar, val){
    match(val){
      case ~{map}:
        match(Map.get("value domain", map)){
          case {none}: false
          case {some: s}:
            match(s){
              case {map: varMap}:
                match(Map.get(searchVar, varMap)){
                  case {none}: false
                  case {some: result}:
                    match(result){
                      case ~{data}: f(data);
                      default: false;
                    }
                }
              default: false;
            }
        }
      default: false;
    }
  }

  server function option(expr) parse(string query) {
    Parser.try_parse(S, query);
  }

  server function option(list(string)) parse_and_search(string id, string query){
    match(parse(query)){
      case {some: res}:
        Log.debug("Search","parsed expression: {res}");
        {some: search(id, res)};
      case {none}:
        Log.error("Search", "failed parsing {query}");
        {none}
    }
  }

  /**
   * var -> (^[=()&|] .)*
   * C -> var=[0-9]*
   *      var=\"(^[\"] .)*\"
   */
  private C =
    var = parser {
      case v=((![=()&|<>\[\]] .)*): Text.to_string(v);
    }
    val = parser {
      case v=((![&|()] .)*): Text.to_string(v);
    }
    cmp = parser {
      case "=": {eq_}
    }
    icmp = parser {
      case ">": {gt_}
      case "<": {lt_}
    }
    node = parser {
      case n=((![,}] .)*): Text.to_string(n);
    }
    recursive node_list = parser {
      case "," ~node ~node_list: [node | node_list];
      case "": [];
    }
    dec = parser {
      case i=Rule.integer: i;
    }

    parser {
      case "\{dead\}": {unreachables}
      case "\{" ~node ~node_list "\}": {nodes: [node | node_list]};
      case ~var "[" i1=dec ";" i2=dec "]": {~var, d1: i1, d2: i2, vcmp: {in_}}
      case ~var ~cmp ~val: {~var, ~val, ~cmp}
      case ~var ~icmp ~dec: {~var, ~dec, ~icmp}
    }
  /**
   * T -> (S)
   *      !S
   *      C
   */
  private Parser.general_parser(expr) T =
    parser {
      case "(" expr=S ")": expr
      case "!" expr=S: {e: expr, un: {not_}}
      case "<" expr=S: {e: expr, un: {pre_}}
      case ">" expr=S: {e: expr, un: {post_}}
      case cond=C: cond
    }
  /**
   * B -> |S
   *      &S
   */
  private Parser.general_parser({binop binop, expr expr}) B =
    parser {
      case "|" expr=S: {binop: {or_}, ~expr}
      case "&" expr=S: {binop: {and_}, ~expr}
    }
  /**
   * S -> TB
   *      T
   */
  private Parser.general_parser(expr) S = parser {
    case term=T e=B: {e1: term, e2: e.expr, bi: e.binop}
    case term=T: term
  }
}