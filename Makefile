########################################
# USER VARIABLES
EXE = goblintweb.exe
PORT = 8080
PWD ?= $(shell pwd)

# 8: everything
# 7: debug, but not info
# 6: default, no debug
RUN_OPT = --verbose 8 --goblint "../analyzer/goblint" --localmode true --startfolder "$(PWD)"
OTHER_DEPENDS = resources/*
CONFIG = --conf opa.conf --conf-opa-files
FLAG = --opx-dir _build --import-package stdlib.database.mongo

ifdef SystemRoot
	RUN_CMD = $(EXE)
else
	RUN_CMD = ./$(EXE)
endif

########################################
# MAKEFILE VARIABLES
OPA = opa $(FLAG) $(OPAOPT)
BUILDDIR ?= _build
export BUILDDIR
# PLUGINS = $(patsubst %, $(BUILDDIR)/%.opp, $(basename $(notdir $(wildcard plugins/*.js))))
PLUGINS = $(BUILDDIR)/dotrenderer.opp $(BUILDDIR)/util.opp $(BUILDDIR)/prettify.opp

default: exe

# compile the plugins
$(BUILDDIR)/%.opp: plugins/%.js
# hack: remove all opx to ensure the .opp files are not cached
	rm -rf $(wildcard $(BUILDDIR)/*.opx)
	opa-plugin-builder --js-validator-off $^ --build-dir $(BUILDDIR) -o $(@F)

js_plugins: $(PLUGINS)

# Different run definitions: run, debug, test
run: exe
	$(RUN_CMD) $(RUN_OPT) || true

test: exe
	$(RUN_CMD) $(RUN_OPT) --testfile "../analyzer/tests/regression/" || true

debug: exe
	$(RUN_CMD) $(RUN_OPT) --testfile $(file) || true #--opentests "google-chrome"

exe: $(EXE)

pack:

########################################
# EXECUTABLE BUILDING
$(EXE): pack $(PLUGINS)
	@echo "### Building executable $(EXE)"
	$(OPA) $(CONFIG) $(PLUGINS) -o $@ --build-dir $(BUILDDIR)/$(EXE)

$(EXE:%.exe=%.run) : $(EXE)
	./$(EXE) -p $(PORT)

########################################
# CLEANING
clean:
	rm -rf $(BUILDDIR) 2>/dev/null
	rm -f $(EXE) 2>/dev/null
	rm -rf cfgs 2>/dev/null
	rm -rf input 2>/dev/null
	rm -rf result 2>/dev/null
	rm -f result.xml 2>/dev/null
	rm -rf _tracks 2>/dev/null
