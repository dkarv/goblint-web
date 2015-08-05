########################################
# USER VARIABLES
EXE = goblintserver.exe
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

RUN_OPT = --verbose 8 --goblint "../analyzer/goblint"
# 8: everything
# 7: debug, but not info
# 6: default, no debug

default: exe

run: exe
	$(RUN_CMD) $(RUN_OPT)

include Makefile.common
