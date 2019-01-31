# Copyright 2019 Hunter Damron
# TODO: deal with default blocks in noweb <<*>>=
# TODO: detect which sources need to be compiled and run by inspecting the TeX file (possibly via auxillary file)

# BEGIN USER VARIABLES
MORECLEAN=
AUX_EXTENSIONS+=h hpp # Extensions of additional files which are important but are not compiled
# END USER VARIABLES

# TODO eventually BUILD will be user changeable
BUILD=build
NOWEBS=$(wildcard *.nw)
#NOWEBS=$(shell find . -name "*.nw")  # TODO make this makefile work with arbitrary structure
PDFS=$(patsubst %.nw,%.pdf,$(NOWEBS))

NOWEAVE=noweave
NOTANGLE=notangle

LATEXMK=latexmk
LATEXMKFLAGS=-outdir=$(BUILD) -pdf -interaction=nonstopmode --shell-escape

.PHONY: all
all: $(PDFS)

$(PDFS): %.pdf: $(BUILD)/%.pdf
	cp $< $@

%.pdf: %.tex
	$(LATEXMK) $(LATEXMKFLAGS) $<

$(BUILD)/%.tex: %.nw | $(BUILD)
	$(NOWEAVE) -delay -latex $< > $@

# $(NOWEBRULES): $(NOWEBS) | $(BUILD)
# 	./noweb_rules.py > $@

$(BUILD):
	mkdir -p $(BUILD)

.PHONY: clean
clean:
	rm -rf $(BUILD) $(PDFS) $(MORECLEAN)

OUTPUT_EXTENSIONS:=$(patsubst \%.%.output:,%,$(shell grep -oh '^%\..*\.output:' $(MAKEFILE_LIST)))
EXTENSIONS=$(OUTPUT_EXTENSIONS) $(AUX_EXTENSIONS)

EXTGRP=$(shell echo $(EXTENSIONS) | tr -s ' ' | sed 's/ /\\|/g')
NOWEBDEPS=$(patsubst <<%>>=,%,$(shell grep -oh '<<.*\.\($(EXTGRP)\)>>=' $(1)))  # Function which gets deps of a nowebfile

NOTANGLE_RULE=$(NOTANGLE) -R$(patsubst $(BUILD)/%,%,$@) $^ > $@  # TODO put this inside instead

define NOTANGLEDEP
tangled:=$$(addprefix $(BUILD)/,$$(strip $$(call NOWEBDEPS,$(1))))
$$(tangled): $(1) | $(BUILD)
	$$(NOTANGLE_RULE)
$$(patsubst %.nw,$(BUILD)/%.pdf,$(1)): $$(patsubst %,%.output,$$(tangled))
endef

$(foreach nw, $(NOWEBS), $(eval $(call NOTANGLEDEP,$(nw))))

define EMPTYDEP
%.$(1).output : %.$(1)  # Don't remove the space before the colon
	touch $$@
endef
$(foreach ext,$(AUX_EXTENSIONS),$(eval $(call EMPTYDEP,$(ext))))

-include user_rules.mk

### Default output rules
%.py.output: %.py
	python $< > $@

%.cpp.output: %.exe %.cpp
	./$< > $@

# TODO figure out why % rules fail
%.exe: %.cpp
	g++ $< -o $@

%.cpp: %.hpp
