type context = list(string);

// fail: parsing failed. it makes no sense to continue
// next: continue with that parser
// retry: it failed, but please retry with this parser
type result = {state next} or {string fail} or {state retry}

// parameters: id, line
// return: the result of parsing.
type state = (string, string -> result)

module ResultParser2 {
// TODO optimize
  int READ_SIZE = 1000;
  OPTIONS = {none};

  function void parse_file(string file){
    fd = File.open(file, "r", {none});

    // do all the parsing here
    string random = Random.string(16);
    // rec_parse(fd, [], random, params);
    rec_parse(fd, [], random, run);
    Log.debug("Parser","inserted id: {random}");

    match(File.close(fd)){
      case {none}:
        void
      case {some: err}:
        Log.debug("ResultParser","error closing the file: {err}");
    }
  }

  function void rec_parse(fd, ctx, id, st){
    match(read_line(fd, ctx)){
      case {some: (line, context)}:
        // Log.debug("Reading",line);
        new_state = parse(st, line, id);
        rec_parse(fd, context, id, new_state);
      default:
        Log.debug("Parser","finished reading file");
    }
  }

  function parse(state st, string line, string id){
    match(st(id, line)){
      case {fail: msg}:
        @fail("can't parse '{line}': {msg}");
      case {retry: new_st}:
        parse(new_st, line, id);
      case {next: new_st}:
        new_st;
    }
  }

  /**
   * 1. parser
   * 2. save function
   * 3. next: return the result
   * 4. fail function: what next if parsing failed?
   * 5. id
   * 6. line
   */
  function may(
    Parser.general_parser('a) p,
    (string, 'a -> void) save,
    ('a -> result) next,
    (-> result) fail,
    string id, string line){
      match(Util.try(p,line)){
        case {none}:
          fail();
        case {some: res}:
          save(id, res);
          next(res);
      }
  }

  must = may(_,_,_,(-> result) function(){
    {fail: "was expecting another value"}
  }, _, _);

  str = function(string should, state next, id,line){
    if(line == should){
      {next: next}
    } else {
      {fail: "expecting: " ^ should}
    }
  }

  ('a, 'b -> void) trash = function(_,_){ void }

  (string, ('a -> result) -> (-> result)) close = function(tag, next){
    function(){
      {retry: must(Util.close_tag(tag), trash, next, _, _)}
    }
  }

  state run = str("<run>",par,_,_);
  state par = str("<parameters>",params,_,_);
  state params = function(id,line){
    Database.save_parameter(id, line);
    {next: end_par};
  }
  state end_par = str("</parameters>",res,_,_);
  state res = str("<result>",files,_,_);
  // state end_run = str("</run>",res,_,_);

  recursive state files = may(Util.file_parser, Database.add_file, function(file){
    {next: functions(file.path)}
  }, function(){
    {retry: calls}
  },_,_);

  (string -> state) functions = function(string filepath){
    may(Util.fkt_parser, Database.add_fkt(_,filepath,_), function(fkt){
      {next: nodes(filepath, fkt.name)}
    }, close("file", function(_){ {next: files} }), _, _);
  }

  recursive (string, string -> state) nodes = function(string filepath, string fktname){
    may(Util.node_parser, Database.add_fkt_node(_,filepath, fktname,_), function(node){
      {next: nodes(filepath, fktname)}
    }, close("function", function(_){ {next: functions(filepath)} }), _, _);
  }

  recursive calls = may(Util.call_parser, Database.add_call, function(call){
      {next: context(call.line, 0)}
    }, function(){
      {retry: globs}
    }, _, _);

  (int, int -> state) context = function(int call_line, int ctx_num){
    function(id,line){
      if(line == "<context>"){
        {next: analysis(call_line, ctx_num, Database.add_context_ana(id,call_line, _,_,_))}
      } else {
        close_call(line);
      }
    }
  }

  close_call = function(line){
    if(line == "</call>"){
      Log.debug("Parser","found closing call");
      {next: calls}
    } else {
      {fail: "expecting </call>"}
    }
  }

  path = function(int call_line, int path_num){
    function(id,line){
      if(line == "<path>"){
        {next: analysis(call_line, path_num, Database.add_path_ana(id,call_line, _,_,_))}
      } else {
        Log.debug("Parser","found no path for the context");
        close_call(line);
      }
    }
  }

  analysis = function(int call_line, int number, save){
    may(Util.analysis_parser, trash, function(string ana_name){
      {next: value(function(val){
        // Log.debug("ana.value result:","{print_value(val)}");
        save(number, ana_name, val);
        {next: function(_,line){
          if(line == "</analysis>"){
            {next: analysis(call_line, number, save)}
          } else {
            {fail: "expecting '</analysis>'"}
          }
        }}
      },_,_)}
    }, function(){
      {retry: function(_,line){
        if(line == "</context>"){
          Log.debug("closed","context");
          {next: path(call_line, number)}
        } else {
          if(line == "</path>"){
            Log.debug("closed","path");
            {next: context(call_line, number + 1)}
          } else {
            {fail: "expected closing context or path"}
          }
        }
      }}
    },_,_);
  }

  value = function((value -> result) callback,id,line){
    if(line == "<value>"){
      {next: inner_value(function(value){
        {next: function(_, line){
          if(line == "</value>"){
            callback(value);
          } else {
            {fail: "expecting '</value>'"}
          }
        }}
      }, _, _)}
    } else {
       // Log.debug("data_val","assume this is data: " ^ line);
       callback({data: line});
    }
  }

  function inner_value(callback, id, line) {
    // test here if it is a map, set or data and return the corresponding parser for the next line
    match(Util.try(Util.inner_value, line)){
      case {none}: {fail: "can't parse inner value"}
      case {some: {data}}: {next: data_val(callback, _,_)};
      case {some: {map}}: {next: key_val(callback, Map.empty, _, _)}
      case {some: {set}}: {next: set(callback, List.empty, _, _)}
    }
  }

  function data_val(callback, _, line){
    // Log.debug("data_val","assume this is data: " ^ line);
    result next = callback({data: line});
    {next: must(Util.close_tag("data"), trash, function(_){ next }, _, _)}
  }

  function key_val(callback, map, _, line){
    if(line == "<key>"){
      {next: function(_, key){
        //Log.debug("key:",key);
        {next: function(_, line){
          if(line == "</key>"){
            {next: value(function(val){
              // Log.debug("found","'{key}' -> {val}");
              {next: key_val(callback, Map.add(key, val, map), _, _)}
            },_,_)}
          } else {
            {fail: "found no closing </key>"}
          }
        }}
      }}
    } else {
      if(line == "</map>"){
        callback(~{map})
      } else {
        {fail: "expected <key> or </map>"}
      }
    }
  }

  function set(callback,list(value) ls, id, line){
    if(line == "</set>"){
      callback({set: List.rev(ls)});
    } else {
      value(function(value){
        {next: set(callback,[ value | ls],_,_)}
      }, id, line);
    }
  }

  globs = function(_, line){
    if(line == "<glob>"){
      Log.debug("Parser","found glob");
      {next: str("<key>", function(_,line){
        Log.debug("glob key:","{line}");
        {next: str("</key>",inner_glob(line,_,_),_,_)}
      },_,_)}
    } else {
      {retry: warnings}
    }
  }

  inner_glob = function(key,id,line){
    {retry: print}
  }

  warnings = function(_,line){
    if(line == "<warning>"){
      Log.debug("Parser","found warning");
      {next: print}
    } else {
      {retry: end}
    }
  }

  end = function(_,line){
    if(line == "</result>"){
      {next: function(_,line){
        if(line == "</run>"){
          {next: fail}
        } else {
          {fail: "expected </run>"}
        }
      }}
    } else {
      {fail: "expected </result>"}
    }
  }

  fail = function(_,_){
    {fail: "expected end of file"}
  }

  function result print(_, string line) {
    Log.debug("",line);
    {next: print}
  }

  function option((string, context)) read_line(fd, context){
    match(context){
      case []:
        newlines = fill_buffer(fd, "");
        if(List.is_empty(newlines)){
          {none}
        } else {
          read_line(fd, newlines);
        }
      case [a]:
        read_line(fd, fill_buffer(fd, a));
      case [x | xs]:
        {some: (x, xs)};
    }
  }

  function context fill_buffer(fd, remaining){
    content = File.d_read(fd, READ_SIZE, OPTIONS);
    if(Binary.length(content) == 0){
      if(String.is_empty(remaining)){
        []
      }else{
        [remaining, ""]
      }
    } else {
      str = remaining ^ Binary.to_string(content);
      match(explode(str)){
        case []:
          @fail("empty file?");
        case [a]: // continue filling the buffer
          fill_buffer(fd, a);
        case xs:
          xs;
      }
    }
  }

  function list(string) explode(string str){
    source_len = String.length(str);

    recursive aux_sep = function(acc, pos, len){
      if(pos == source_len){
        if(len == 0){
          List.rev(acc);
        } else {
          List.rev([ String.substring_unsafe(pos - len, len, str) | acc]);
        }
      } else {
        c = String.char_at(str, pos);
        lt = c == 60;
        gt = c == 62;
        // 10: \n, 60: <, 62: >
        if(c == 10 || lt || gt){
          new_len = if(lt){ 1 } else { 0 }
          if(len == 0){// empty line -> remove
            aux_sep(acc, pos + 1, new_len);
          } else {
            cut_len = if(gt){ len + 1 } else { len }
            sub = String.substring_unsafe(pos - len, cut_len, str);
            // Log.debug("sub",sub);
            aux_sep([ sub | acc], pos + 1, new_len);
          }
        } else {
          aux_sep(acc, pos + 1, len + 1);
        }
      }
    };

    aux_sep([],0, 0);
    //res;
  }

  function print_value(value val){
    match(val){
      case {data: d}: "'{d}'"
      case {map: m}: "[" ^ Map.fold(function(key, val, acc){
        acc ^ "\n" ^ key ^ "->" ^ print_value(val);
      }, m, "") ^ "]" ;
      case {set: s}: "[" ^ List.fold(function(val, acc){
        acc ^ print_value(val) ^ ", ";
      }, s, "") ^ "]";
    }
  }
}