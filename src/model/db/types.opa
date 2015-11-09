/**
 * contains the most important types.
 * the main advantage is, that you can import them without a big overhead.
 */
type vertex = {
  string id,
  string shape,
  string label
}

type edge = {
  string start,
  string end,
  string label
}
/**
 * internal representation of a graph.
 */
type graph = {
  list(edge) edges,
  list(vertex) vertices
}

/*
 * representation of a list of edges.
 * the tupels represent (nodes, outgoing label)
 * e is the last node of the edges
 * a is the first one, together with the first label
 */
type edges = {
  (string, string) a,
  string e,
  list((string, string)) es
}

type ana = {
  string id,
  string filename,
  graph cfg,
  run run
}

type value = {
  stringmap(value) map
} or {
  list(value) set
} or {
  string data
}

type analysis = {
  string name,
  value val
}

type call = {
  string id,
  string file,
  int line,
  int order,
  list(analysis) context,
  list(analysis) path
}

type warnitem = {
  string file,
  int line,
  string txt
}

type warning = {
  string group,
  list(warnitem) items
}

type fkt = {
  string name,
  list(string) nodes
}

type file = {
  string name,
  string path,
  list(fkt) fkt
}

type run = {
  string parameters,
  list(file) files,
  intmap(call) line_calls,
  stringmap(call) id_calls,
  list(string) call_ids,
  list(analysis) globs,
  list(warning) warnings,
  list(string) unreachables
}

module Types{

}