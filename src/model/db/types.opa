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