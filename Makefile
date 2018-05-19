########################################################################
# Essentials Templates

INC_BASE    = .
INC_GIT     = $(INC_BASE)/git.mk
INC_LATEX   = $(INC_BASE)/latex.mk
INC_CLEAN   = $(INC_BASE)/clean.mk

define HELP
ESSENTIALS Templates:

  Local Targets

  target	Description

endef
export HELP

help::
	@echo "$$HELP"

include $(INC_GIT)
include $(INC_LATEX)
include $(INC_CLEAN)

# .PHONY: help
# help::
# 	@echo -e "Manage building of the Articulate book\n\
# 	======================================\n\
# 	%.view        \tPreview a pdf.\n\n\
# 	book          \tCompile the book.\n\
# 	uploads	      \tUpload scripts to $(SCRIPTS)\n\
# 	clean         \tRemove easily generated PDFs etc.\n\
# 	realclean     \tRemove generated files, including models and data.\n\n\
# 	chapters      \tList the chapters in sequence\n\
# 	functions     \tList the functions per chapter\n\n\
# 	For individual chapters these are processed:\n\
# 	  %.Rnw -> %.R and %.tex -> %.pdf.\n\
# 	For the book the process is:\n\
# 	  %.Rnw -> %.tex -> %Inc.tex -> book.Rnw\n\
# 	"

# 	%.process     \tUpdate title and chapter number.\n\
#	%.error       \tVerbosely process to debug errors.\n\n\
#	Chapters are linked to the corresponding docs in ../onepager\n\

TIMESTAMP = Version: $(shell date +%Y%m%dT%H%M%S)

########################################################################
# LOCATIONS
#
# 160213 Record all locations here. Start unifying with the onepager
# version until merged.

# Location of the Hands On Data Science host and folders.

HO_HOST        = togaware.com
HO_DATA_DIR    = webapps/onepager/data
HO_SCRIPTS_DIR = webapps/onepager/scripts

SCRIPTS_HOST = $(HO_HOST)
SCRIPTS_DIR  = $(HO_SCRIPTS_DIR)
SCRIPTS      = $(HO_HOST):$(SCRIPTS_DIR)

ONEPAGER = ../onepager

# LOGFILE	All output written here

LOGFILE  = cache/build_$(shell date +%y%m%dT%H%M).log
DEST     = webapps/onepager/.rpds
#SCRIPTS  = togaware.com:webapps/togaware/scripts

########################################################################
# Scripts
#
# PROCESSR	Process .Rnw in place to update title and chapter number
# INCLUDER	Process .tex to inc.tex for book
# KNITR		Process .Rnw to .tex
# PURL		Process .Rnw to .R
# CUPLOADS	Upload file to togaware.com
# SPLIT		Split data/model into sequential files.

PROCESSR  = ./scripts/process
INCLUDER  = ./scripts/includer
KNITR     = ./scripts/knitr
PURL      = ./scripts/purl
CUPLOADS  = ./scripts/cuploads
SPLIT     = ./scripts/split
CHAPTERS  = ./scripts/chapters
LINKS     = ./scripts/links
TARGETS   = ./scripts/targets
FUNCTIONS = ./scripts/functions

########################################################################
# FILES

# LNK=$(shell $(TARGETS)) # This considerably slows down the makefile startup
LNK=	DataScienceO.lnk \
	IntroRO.lnk      \
	DataO.lnk        \
	GGPlot2O.lnk 	 \
	PortsO.lnk 	 \
	ATOWebO.lnk 	 \
	ModelsO.lnk 	 \
	EnsModelsO.lnk 	 \
	FunctionsO.lnk   \
        KnitRO.lnk 	 \
	StyleO.lnk 	 \

PDF=$(LNK:.lnk=.pdf) 
RNW=$(LNK:.lnk=.Rnw)
TEX=$(LNK:.lnk=.tex)
RXX=$(LNK:.lnk=.R)
BIB=$(LNK:.lnk=.bib)
INC=$(LNK:.lnk=Inc.tex) 
INS=$(LNK:.lnk=.install)

test:
	echo $(BIB)

pages: $(PDF) $(INC)
	@$(PAGES)

install: book.install $(INS)

########################################################################
# CHAPTER LINKAGES
#
# The definitive linkages come from book.Rnw and are genrated from
# there. We include here additional links required to process the
# book.

#links:
#	$(LINKS)
#	ln -sf $(ONEPAGER)/graphics             .
#	ln -sf $(ONEPAGER)/sty/*		.
#	ln -sf $(ONEPAGER)/cache		.
#	ln -sf $(ONEPAGER)/extra.bib		.
#	ln -sf $(ONEPAGER)/report.Rnw		.

########################################################################
# GENERAL DEPENDENCIES

SUPPORT	=            		\
	Makefile        	\
	mycourse.sty    	\
	mycourse.Rnw    	\
	documentation.Rnw	\
	finale.Rnw      	\
	crossref.tex		\
	extra.bib		\
	krantz.cls		\



########################################################################
# MAKE RULES

# Also generate a new .R each time we build .tex

.PRECIOUS: %.tex
%.tex: %.Rnw %.R $(SUPPORT)
	$(KNITR) $< | tee -a $(LOGFILE)

.PRECIOUS: %.R
%.R: %.Rnw
	R -e "require(knitr); purl('$<')"
	perl -ni -e 'print if !/^## ----/' $@

data.R: data.Rnw
	R -e "require(knitr); purl('$<')"
	perl -ni -e 'print if !/^## ----/' $@
	perl -pi -e 's|DOCVERSION|$(TIMESTAMP)|' $@
	$(SPLIT) $@

.PHONY: data.upload
data.upload: data.Rnw data.R
	chmod a+r $^ ??_?*.R
	rsync -avzh $^ togaware.com:webapps/essentials/
	rsync -avzh $^ ??_?*.R togaware.com:webapps/onepager/scripts/

model.R: model.Rnw
	R -e "require(knitr); purl('$<')"
	perl -ni -e 'print if !/^## ----/' $@
	perl -pi -e 's|DOCVERSION|$(TIMESTAMP)|' $@
	$(SPLIT) $@ | tee -a $(LOGFILE)	

# Keep .bib for use when generating book.

.PRECIOUS: %.bib %.pdf
%.pdf: %.tex
	latexmk -xelatex -pdf -shell-escape $* | tee -a $(LOGFILE)

# After viewing also upload to togaware in the background. The echo -n
# was needed to make this wor as without some commands make claimed it
# did not know how to make?

.PHONY: %.view
%.view: %.eview %.upload
	@echo -n

%.aview: %.pdf %.R
	acroread $< 2>> tee -a $(LOGFILE) &

%.eview: %.pdf %.R
	evince $< &

%.oview: %.pdf %.R
	okular $< &

%.install: %.pdf %.R
	$(CUPLOADS) -n $* &

%.watch:
	@while inotifywait -e close_write $(ONEPAGER)/$*.Rnw; do make $*.pdf; make $*.install; date; done

%.pdf: %.odt
	unoconv -f pdf $^

%.process: %.Rnw
	$(PROCESSR) $<

# When I get an error run this to debug it.

%.error:
	$(PROCESSR) $*.lnk $*.Rnw
	$(KNITR) $*.Rnw
	pdflatex $*
	bibtex $*
	pdflatex $*
	pdflatex $*

########################################################################
# SPECIFIC DEPENDENCIES

IntroROInc.tex:						\
	graphics/rstudio_startup.png			\
	graphics/rstudio_startup_editor.png             \
	graphics/rstudio_weatherAUS_scatterplot.png	\

KnitRO.Rnw:                                             \
	graphics/rstudio_knitr_pdf_sample.png		\
	report-crop.pdf                                 \
	report.Rnw

report-crop.pdf: report.pdf
	pdfcrop --margins "20" report.pdf

# When the following dependency is included "make book" will always
# remake c04 and c05 for some reason... Comment out until it is fixed.

#c04.Rnw: weather_160720.RData
#c05.Rnw: weather_meta_160720.RData

########################################################################
# BOOK TARGETS

%Inc.tex: %.tex $(INCLUDER)
	$(INCLUDER) $< $@

# Build the book from scratch and the upload a timestamped version.

.PHONY: book
book: book.tex book.view
	cp book.pdf ARCHIVE/book_$(shell date +%y%m%dT%H%M).pdf

book.tex: $(INC) book.bib

book.bib: $(INC:Inc.tex=.bib) extra.bib
	bibtool -s -d $^ > $@ 2>> $(LOGFILE)

book.error:
	$(KNITR) book.Rnw
	pdflatex book
	bibtex book
	pdflatex book
	pdflatex book


########################################################################
# UPLOADS

.PHONY: %.upload
%.upload: %.pdf %.R
	$(CUPLOADS) -n $* >> $(LOGFILE) 2>&1 &

.PHONY: cuploads
cuploads: 
	$(CUPLOADS)

########################################################################
# UPLOADS

.PHONY: uploads
uploads: data.R model.R # data.pdf model.pdf
	rsync -aczh $^ data.Rnw model.Rnw ../onepager/facetAdjust.R $(SCRIPTS)
	rsync -achz [0-9][0-9]_*.R $(SCRIPTS)
	ssh $(SCRIPTS_HOST) chmod a+r $(SCRIPTS_DIR)/*

########################################################################
# UTILITIES

.PHONY: functions
functions: 
	@$(FUNCTIONS)

.PHONY: chapters
chapters: 
	@$(CHAPTERS)

.PHONY: links
links: 
	./links


########################################################################
# CLEANUP

clean::
	rm -f *.aux *.bbl *.blg *.idx *.ilg *.ind *.log \
              *.out *.lof *.lot *.toc *.fns *.fdb_latexmk \
	      *.fls *.loe *.xwm
	rm -f *Inc.aux *Inc.tex
	rm -f book.aux book.bbl book.bib book.blg book.idx book.ilg \
	      book.ind book.log book.out book.lof book.lot book.toc \
	      book.fdb_latexmk book.fls book.loe comment.cut

realclean:: clean
	rm -f $(PDF) $(TEX) $(RXX) $(BIB)
	rm -f report.R report.pdf report.tex
	rm -f book.pdf book.R book.tex 
	rm -f data.R data.pdf data.tex
	rm -f [0-9][0-9]_*.R
	rm -f model.R model.pdf model.tex
	rm -f *~ */*~
	rm -rf figures
	rm -rf weather*.RData
	rm -f report-crop.pdf corpus
	rm -f .Rhistory $(LOGFILE)

#togaclean:
#	ssh togaware.com mv $(DEST)/*.pdf $(DEST)/ARCHIVE

williams_k34788.tar.gz:
	tar cvfz $@ \
	book.Rnw \
	DataScienceO.Rnw \
	IntroRO.Rnw \
	DataO.Rnw \
	data.Rnw \
	GGPlot2O.Rnw \
	PortsO.Rnw \
	ATOWebO.Rnw \
	ModelsO.Rnw \
	model.Rnw \
	EnsModelsO.Rnw \
	FunctionsO.Rnw \
	KnitRO.Rnw \
	report.Rnw \
	StyleO.Rnw \
	documentation.Rnw \
	book.tex \
	DataScienceOInc.tex \
	IntroROInc.tex \
	DataOInc.tex \
	GGPlot2OInc.tex \
	PortsOInc.tex \
	ATOWebOInc.tex \
	ModelsOInc.tex \
	EnsModelsOInc.tex \
	FunctionsOInc.tex \
	KnitROInc.tex \
	report.tex \
	StyleOInc.tex \
	extra.bib \
	mycourse.sty \
	datetime2.sty \
	exercise.sty \
	tracklang.sty \
	tracklang.tex \
	jss.bst \
	krantz.cls \
	graphics/rstudio_knitr_pdf_sample_annotate.png \
	graphics/rstudio_knitr_pdf_sample.png \
	graphics/rstudio_startup_editor_annotate.png \
	graphics/rstudio_startup_editor.png \
	graphics/rstudio_startup.png \
	graphics/rstudio_sweave_start.png \
	graphics/rstudio_weatherAUS_scatterplot_annotate.png \
	graphics/rstudio_weatherAUS_scatterplot.png \
	figures/ \
	report-crop.pdf \
	book.bib \
	BUILDME
