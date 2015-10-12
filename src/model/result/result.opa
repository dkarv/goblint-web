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
  list(warning) warnings
}

module Result{

}