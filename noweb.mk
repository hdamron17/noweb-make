# Copyright 2019 Hunter Damron
# TODO: deal with default blocks in noweb <<*>>=
# TODO: detect which sources need to be compiled and run by inspecting the TeX file (possibly via auxillary file)

# BEGIN USER VARIABLES
MORECLEAN=
AUX_EXTENSIONS+=h hpp # Extensions of additional files which are important but are not compiled
# END USER VARIABLES

# TODO eventually BUILD will be user changeable
BUILD=build
NOWEB=$(BUILD)
NOWEBS=$(wildcard *.nw)
#NOWEBS=$(shell find . -name "*.nw")  # TODO make this makefile work with arbitrary structure
PDFS=$(patsubst %.nw,%.pdf,$(NOWEBS))

NOWEAVE=noweave
NOTANGLE=notangle
CPIF=cpif

LATEXMK=latexmk
LATEXMKFLAGS=-outdir=$(BUILD) -pdf -interaction=nonstopmode --shell-escape -g -use-make  # Look at options -M, -MF file

-include user_rules.mk

.PHONY: all
all: $(PDFS)

$(PDFS): %.pdf: $(BUILD)/%.pdf
	cp $< $@

%.pdf: %.tex
	$(LATEXMK) $(LATEXMKFLAGS) $<

$(BUILD)/%.tex: %.nw | $(BUILD)
	$(NOWEAVE) -delay -latex $< > $@

$(BUILD):
	mkdir -p $(BUILD)

.PHONY: clean
clean:
	$(RM) -r $(BUILD) $(PDFS) $(MORECLEAN)

OUTPUT_EXTENSIONS:=$(patsubst \%.%.output:,%,$(shell grep -oh '^%\..*\.output:' $(MAKEFILE_LIST)))
EXTENSIONS=$(OUTPUT_EXTENSIONS) $(AUX_EXTENSIONS)

EXTGRP=$(shell echo $(EXTENSIONS) | tr -s ' ' | sed 's/ /\\|/g')
NOWEBDEPS=$(patsubst <<%>>=,%,$(shell grep -oh '<<.*\.\($(EXTGRP)\)>>=' $(1)))  # Function which gets deps of a nowebfile

define NOTANGLEDEP
tangled:=$$(addprefix $$(BUILD)/,$$(strip $$(call NOWEBDEPS,$(1))))
$$(tangled): $(BUILD)/%: $(1) | $$(BUILD)
	$$(NOTANGLE) -R$$* $$^ | $$(CPIF) $$@
$$(patsubst %.nw,$$(BUILD)/%.pdf,$(1)): $$(patsubst %,%.output,$$(tangled))
endef

$(foreach nw, $(NOWEBS), $(eval $(call NOTANGLEDEP,$(nw))))

define EMPTYDEP
%.$(1).output : %.$(1)  # Don't remove the space before the colon
	touch $$@
endef
$(foreach ext,$(AUX_EXTENSIONS),$(eval $(call EMPTYDEP,$(ext))))

### Default output rules
PY=python
PYFLAGS=

MATLAB=matlab
MATLABFLAGS=-nosplash -nodesktop

%.py.output: %.py
	cd $(*D) && $(PY) $(PYFLAGS) $(<F) > $(@F)

%.cpp.output: %.exe %.cpp
	cd $(*D) && ./$(<F) > $(@F)

# TODO figure out why % rules fail
%.exe: %.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

%.m.output: %.m
	cd $(*D) && $(MATLAB) $(MATLABFLAGS) -r "echo on, try, run(\"$(<F)\"), catch e, getReport(e, 'extended'), exit, end, exit" | tail -n+11 | sed -e '$$ d' > $(@F)


# These dependencies don't work for some reason
%.cpp: %.hpp
%.c: %.h
