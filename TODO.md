# TODOs
- save arguments goblint was called with, and show them after F5
- arguments suggestions:
  - {main,exit,other}fun: functions in code
  `grep -Po "(?<=int )[^)]+(?=\(\))" ../analyzer/tests/regression/06-symbeq/22-var_eq_types.c`
  - ana.{activated,path_sens,ctx_insens}: `grep -Proh "(?<=let name = \")[^\"]+(?=\")" ../analyzer/src/analyses/`
- unit tests:
