module Controller {

  function rest(param) {
    match (HttpRequest.get_method()) {
    case {some: method} :
      match (method) {
      case {post}:
        post(param);
      case {get}:
        get(param);
      default:
        Resource.raw_status({method_not_allowed});
      }
    default:
      Resource.raw_status({bad_request});
    }
  }

  function get(path) {
    match (path) {
    case ["analysis", id ]:
      ana a = Model.get_analysis(id);
      Resource.raw_response(a.src, "text/plain", {success});
    case ["cfg", id ] :
      ana a = Model.get_analysis(id);
      match (a.cfg) {
      case {some: g}:
        ls = List.map(function(elem) { elem.start ^ "->" ^ elem.end}, g.edges);
        ts = List.fold_left(function(acc, elem) { acc ^ "; " ^ elem},"",ls);
        Resource.raw_response(ts, "text/plain", {success});
      case {none}: Resource.raw_response("no cfg yet", "text/plain", {bad_request});
      }
    default:
      Resource.raw_response("rest route not found", "text/plain", {bad_request});
    }
  }

  function post(path) {
    match (path) {
    case ["analysis"]:
      match (HttpRequest.get_body()){
      case {~some}:
        string id = Model.save_analysis("uploaded",some);
        Resource.raw_response(id, "text/plain", {success});
      default:
        Resource.raw_response("no body specified", "text/plain", {bad_request});
      }
    //case ["testparser"]:
    //  match (HttpRequest.get_body()){
    //    case {~some}:
    //      Log.error("Controller","{some}");
    //      Model.test_parser(some);
    //      Resource.raw_response("fine", "text/plain", {success});
    //    case {none}:
    //      Resource.raw_response("no body specified", "text/plain", {bad_request});
    //  }
    default:
      Resource.raw_status({bad_request});
    }
  }

  function start(url) {
    match (url) {
    case {path:[] ...}: View.show_root();
    case {path: ["rest" | path] ...}: rest(path);
    case {path: ["analysis" , id] ...}: View.show_analysis(Model.get_analysis(id));
    case {~path ...}: Resource.raw_status({bad_request});
    }
  }
}

resources = @static_resource_directory("resources")

Server.start(Server.http, [
  { register:
    [ { doctype: { html5 } },
      { js: [ "/resources/lib/d3.min.js", "/resources/lib/dagre.min.js",
        "/resources/lib/dagre-d3.min.js", "/resources/lib/graphlib-dot.min.js",
        "/resources/lib/prettify.js"] },
      { css: [ "/resources/css/layout.css", "/resources/css/prettify.css"] },
      { favicon: [ Favicon.make({ico},"/resources/favicon.ico")]}
    ]
  },
  { ~resources },
  { dispatch: Controller.start }
])
