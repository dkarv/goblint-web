type unop = {not_}
type binop = {and_} or {or_}
type comp = {eq_}
type expr =
  /** var == value */
  {string var, string val, comp cmp} or
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
        case {var: searchVar, val: searchValue, cmp: {eq_}}:
          Map.To.key_list(
            Map.filter(function(_, val){
              List.exists(function(el){
                if(String.eq("base", el.name)){
                  // Log.debug("Search","val: {el.val}");
                  match(el.val){
                    case ~{map}:
                      // search for the value domain in the map
                      match(Map.get("value domain", map)){
                        case {none}:
                          {false}
                        case {some: s}:
                          // Log.debug("Search","map: {s}");
                          // ensure s is a map again:
                          match(s){
                            case {map: varMap}:
                              // Log.debug("Search", "varMap: {varMap}");
                              // now search for the right variable
                              match(Map.get(searchVar, varMap)){
                                case {none}:
                                  {false}
                                case {some: result}:
                                  match(result){
                                    case ~{data}:
                                      Log.debug("Search","found: {data} == {searchValue}");
                                      String.eq(data, searchValue);
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
    };

    inner(query);
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
      case v=((![=()&|] .)*): Text.to_string(v);
    }
    val = parser {
      case "\"" v=((!["\""] .)*) "\"": Text.to_string(v);
      case v=([0-9]+): Text.to_string(v);
    }
    parser {
      case ~var "=" ~val: {~var, ~val, cmp: {eq_}}
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