/**
 * contains the most important types.
 * the main advantage is, that you can import them without a big overhead.
 */

// (id, label): label that targets the next node
type node = (string, string)

/*
 * representation of a list of edges.
 * e is the last node of the edges
 * a is the first one, together with the first label
 */
type edges = {
  node a,
  string e,
  list(node) es
}

/**
 * internal representation of a graph.
 * list of list of edges basically
 */
type graph = multimap(string, edges, String.order)

type ana = {
  string id,
  string filename,
  graph cfg,
  list(string) start_nodes,
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
  // list(context, path)
  list((list(analysis), list(analysis))) anas
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
  stringmap(fkt) fkt
}

type run = {
  string parameters,
  // file.path -> file
  stringmap(file) files,
  intmap(call) line_calls,
  stringmap(int) id_to_line,
  list(string) call_ids,
  list(analysis) globs,
  list(warning) warnings,
  list(string) unreachables
}

type maybe('a) = {'a success} or {string error}

module Types{

}