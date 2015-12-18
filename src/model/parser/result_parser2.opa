type context = list(string);

// fail: parsing failed. it makes no sense to continue
// next: continue with that parser
// retry: it failed, but please retry with this parser
type result = {state next} or {fail} or {state retry}

// parameters: id, line
// return: the result of parsing.
type state = (string, string -> result)

module ResultParser2 {

  int READ_SIZE = 1000;
  OPTIONS = {none};

  function void parse_file(string file){
    fd = File.open(file, "r", {none});

    // do all the parsing here
    string random = Random.string(16);
    rec_parse(fd, [], random, params);
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
      case {fail}:
        @fail("can't parse '{line}'");
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
    {fail}
  }, _, _);

  ('a, 'b -> void) trash = function(_,_){ void }

  (string, ('a -> result) -> (-> result)) close = function(tag, next){
    function(){
      {retry: must(Util.close_tag(tag), trash, next, _, _)}
    }
  }

  state params = must(Util.parameters, Database.save_parameter, function(string res){
    {next: files}
  },_,_);

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

  (string, string -> state) nodes = function(string filepath, string fktname){
    may(Util.node_parser, Database.add_fkt_node(_,filepath, fktname,_), function(node){
      {next: nodes(filepath, fktname)}
    }, close("function", function(_){ {next: functions(filepath)} }), _, _);
  }

  calls = todo;


  function result todo(string id, string line) {
    {next: todo}
  }

  /*
      case ~{file}:
        match(Util.try(Util.fkt_parser, line)){
          case {none}:
            parse(line, id, {end: {files}});
          case {some: fkt}:
            Database.add_fkt(id, file, fkt);
            {file: file, fkt: fkt.name}
        }
      case ~{file, fkt}:
        match(Util.try(Util.node_parser, line)){
          case {none}:
            parse(line, id, {end: ~{file}});
          case {some: node}:
            Database.add_fkt_node(id, file, fkt, node);
            st
        }
      case {calls}: {test}
      case {end: x}:
        Log.debug("Parser","parsing end of {x}");
        {test}
      case {test}: {test}
      //default:
      //  5000
        // @fail("unknown state: {state}")
    }
  }*/

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
      match(String.explode_with("\n",str, false)){
        case []: @fail("empty file?");
        case [a]: // continue filling the buffer
          fill_buffer(fd, a);
        case xs: xs;
      }
    }
  }
}