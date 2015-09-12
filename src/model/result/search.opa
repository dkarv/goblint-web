type unop = {not_}
type binop = {and_} or {or_}
type comp = {eq_}
type icomp = {gt_} or {lt_}
type vcomp = {in_}
type expr =
  /** var == value */
  {string var, string val, comp cmp} or
  {string var, int dec, icomp icmp} or
  {string var, int d1, int d2, vcomp vcmp} or
  /** this | that */
  {expr e1, expr e2, binop bi} or
  /** !(not)*/
  {expr e, unop un}


/** allows you to search on a graph */
module Search {
  exposed function list(string) search(string id, expr query){
    // Log.debug("Search","starting search");
    stringmap(call) calls = Model.get_id_map(id);
    list(string) nodes = Map.To.key_list(calls);
    // wtf: this function -> void is necessary for the compiler...
    Log.debug("Search","wtf");

    recursive function list(string) inner(expr query){
      match(query){
        case {e: e, un: {not_}}:
          list(string) res_e = inner(e);
          List.filter(function(el){
            if(List.mem(el, res_e)){{false}}else{{true}};
          }, nodes);
        case {~e1, ~e2, bi: {and_}}:
          list(string) res_e1 = inner(e1);
          list(string) res_e2 = inner(e2);
          List.filter(function(el){
            List.mem(el, res_e1);
          }, res_e2);
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
          Log.debug("Search","wtf");
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
    Map.To.key_list(
      Map.filter(function(_, val){
        List.exists(function(el){
          if(String.eq("base", el.name)){
            match(el.val){
              case ~{map}:
                // search for the value domain in the map
                match(Map.get("value domain", map)){
                  case {none}:
                    {false}
                  case {some: s}:
                    // ensure s is a map again:
                    match(s){
                      case {map: varMap}:
                        // now search for the right variable
                        match(Map.get(searchVar, varMap)){
                          case {none}:
                            {false}
                          case {some: result}:
                            match(result){
                              case ~{data}:
                                f(data);
                              default:
                                {false}
                            }
                        }
                      default: {false}
                    }
                }
              default:
                {false}
            }
          }else{
            {false}
          }
        },val.path);
      }, calls)
    );
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

    dec = parser {
      case i=Rule.integer: i;
    }
    parser {
      case ~var "[" i1=dec ";" i2=dec "]": {~var, d1: i1, d2: i2, vcmp: {in_}}
      case ~var ~cmp ~val: {~var, ~val, ~cmp}
      case ~var ~icmp ~dec: {~var, ~dec, ~icmp}
      // TODO add more: unlike, bigger, contains, ...
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