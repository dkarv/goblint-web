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
  list(analysis) globs
}

module Result{

}