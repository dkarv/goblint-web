########################################
# USER VARIABLES
EXE = goblintweb.exe
ifdef SystemRoot
	RUN_CMD = $(EXE)
else
	RUN_CMD = ./$(EXE)
endif

PACKNAME =
SRC =
PCKDIR = ./plugins/
PCK =
PLUGIN = 
PLUGINDIR =
OTHER_DEPENDS = resources/*
CONF_FILE = opa.conf
# javascript bindings
BINDINGS := $(wildcard resources/bind/*.js)


#Compiler variables
OPACOMPILER ?= opa
FLAG = --opx-dir _build --import-package stdlib.database.mongo
PORT = 8080

# RUN_OPT = --verbose 8 --goblint "../analyzer/goblint" --localmode true --startfolder "/home/david/git/analyzer/tests/regression/00-sanity/"
RUN_OPT = --verbose 8 --goblint "../analyzer/goblint" --localmode true --startfolder "/"
# 8: everything
# 7: debug, but not info
# 6: default, no debug

default: exe

run: exe
	$(RUN_CMD) $(RUN_OPT)

test: exe
	$(RUN_CMD) $(RUN_OPT) --testfile "../analyzer/tests/regression/"

debug: exe
	$(RUN_CMD) $(RUN_OPT) --testfile $(file) --opentests "google-chrome"

include Makefile.common
