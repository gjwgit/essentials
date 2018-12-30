########################################################################
#
# Makefile template for KnitR/Sweave Documents - knitr
#
# Copyright 2018 (c) Graham.Williams@togaware.com
#
# License: Creative Commons Attribution-ShareAlike 4.0 International.
#
########################################################################

########################################################################
# HELP

define KNITR_HELP
KnitR Dcoument Management:

  %.tex		Generate LaTeX from .Rnw file.
  %.R		Generate R script from .Rnw file.
  %.run	        Run the extracted R script.
  %.watch	Continually update the PDF file as Rnw changes.

endef
export KNITR_HELP

help::
	@echo "$$KNITR_HELP"

########################################################################
# RULES

.PRECIOUS: %.tex
%.tex: %.Rnw %.R $(RNW_SUPPORT)
	R -e "require(knitr); knit('$<')"

.PRECIOUS: %.R
%.R: %.Rnw
	R -e "require(knitr); purl('$<')"
	perl -ni -e 'print if !/^## ----/' $@

.PHONY: %.run
%.run: %.R
	Rscript $^

%.watch:
	@while inotifywait -e close_write $*.Rnw; do make $*.pdf; date; done

realclean:: *.Rnw
	rm -f $(^:.Rnw=.R) $(^:.Rnw=.pdf) $(^:.Rnw=.tex)
