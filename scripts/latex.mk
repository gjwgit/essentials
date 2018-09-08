########################################################################
#
# Makefile template for LaTeX Document Management - latex
#
# Copyright 2018 (c) Graham.Williams@togaware.com
#
# WARNING - under development 20180507.
#
# License: Creative Commons Attribution-ShareAlike 4.0 International.
#
########################################################################

define LATEX_HELP
LATEX Document Management:

  default	pdf $(APP) then xview $(APP).pdf
  2x3		$(APP)-2x3.pdf
  2x3.view	xview
  1x1		$(APP)-1x1.pdf
  1x1.view	xview
  1x2		$(APP)-1x2.pdf
  1x2.view	xview

  General Targets

  *-2x3.pdf 	for 6up slides
  *-1x1.pdf	for 1 slide per half page with blank below for notes
  *-1x2.pdf	for 2 slides per page with blank below for notes

  Viewing Options

  *.cview	use pdfcube to have a visual cube effect for transitions
  *.kview	use excellent keyjnote view for presentations

endef
export LATEX_HELP

help::
	@echo "$$LATEX_HELP"

# XPDFGEOM = -g 660x930

#
# Don't remove intermediate pdf file.
#
.PRECIOUS: $(root).pdf

wc: $(APP).pdf
	@pdftotext $< $(APP).tmp
	@wc -w $(APP).tmp
	@rm -f $(APP).tmp

error:
	pdflatex $(APP)
%.error:
	pdflatex $*

pdf: $(APP).pdf
2up: $(APP)-2x1.pdf
4up: $(APP)-2x2.pdf
8up: $(APP)-2x4.pdf

%.pdf: %.tex
	rubber --pdf $*

%.ps: %.pdf
	pdftops $<
#	acroread -toPostScript -size a4 $<

%.tex: %.Rnw
	R -e "require(knitr); knit('$<')"

%.R: %.Rnw
	R -e "require(knitr); purl('$<')"

%.rtf: %.tex
	ltx2rtf $<

########################################################################
# VIEW PDF

view: mview

aview: $(APP).aview
cview: $(APP).cview
eview: $(APP).eview
fview: $(APP).fview
gview: $(APP).gview
kview: $(APP).kview
mview: $(APP).mview
vview: $(APP).vview
xview: $(APP).xview

%.view: %.eview
	

%.aview: %.pdf
	acroread $<

%.cview: %.pdf # Keys: c (cube) h,j,k,l,z (zoom) ESC (exit)
	pdfcube $<

%.eview: %.pdf
	evince $<

%.fview: %.pdf
	xpdf -fullscreen $^

%.gview: %.pdf
	gpdf $<

%.kview: %.pdf #
	keyjnote $<

%.mview: %.pdf
	atril $<

%.vview: %.pdf
	ggv $<

%.xview: %.pdf
	xpdf $(XPDFGEOM) -z page $<

%_nobuild.pdf: %.tex
	perl -pi -e 's|class{beamer}|class[handout]{beamer}|' $*.tex
	rubber --pdf $*
	perl -pi -e 's|class\[handout\]{beamer}|class{beamer}|' $*.tex
	mv $*.pdf $@

# NUP

2x3: $(APP)-2x3.pdf
2x3.view: $(APP)-2x3.xview
1x1: $(APP)-1x1.pdf
1x1.view: $(APP)-1x1.xview
1x2: $(APP)-1x2.pdf
1x2.view: $(APP)-1x2.xview

%-2x3.pdf: %.tex
	perl -pi -e 's|class{beamer}|class[handout]{beamer}|' $*.tex
	rubber --pdf $*
	perl -pi -e 's|class\[handout\]{beamer}|class{beamer}|' $*.tex
	pdfnup --nup 2x3 --delta "1cm 1cm" $*.pdf

%-1x1.pdf: %.tex
	perl -pi -e 's|class{beamer}|class[handout]{beamer}|' $*.tex
	rubber --pdf $*
	perl -pi -e 's|class\[handout\]{beamer}|class{beamer}|' $*.tex
	pdfnup --nup 1x1 --orient portrait --offset "0mm 60mm" --trim "-10mm -10mm -10mm -10mm" --outfile $@ $*.pdf

%-1x2.pdf: %.tex
	perl -pi -e 's|class{beamer}|class[handout]{beamer}|' $*.tex
	rubber --pdf $*
	perl -pi -e 's|class\[handout\]{beamer}|class{beamer}|' $*.tex
	pdfnup --nup 1x2 --orient portrait --offset "-40mm 20mm" --trim "-40mm -40mm -40mm -40mm" --outfile $@ $*.pdf

%-1x3.pdf: %.tex /usr/local/include/latex.mk
	perl -pi -e 's|class{beamer}|class[handout]{beamer}|' $*.tex
	rubber --pdf $*
	perl -pi -e 's|class\[handout\]{beamer}|class{beamer}|' $*.tex
	pdfnup --nup 1x3 --orient portrait --offset "-30mm 2mm" --trim "-40mm -40mm -40mm -40mm" --delta "0mm -82mm" --noautoscale true --outfile $@ $*.pdf

%-1x3.view: %-1x3.pdf
	evince $^

%-2x2.pdf: %.tex
	perl -pi -e 's|class{beamer}|class[handout]{beamer}|' $*.tex
	rubber --pdf $*
	perl -pi -e 's|class\[handout\]{beamer}|class{beamer}|' $*.tex
	pdfnup --nup 2x2 --orient landscape --trim "-10mm -10mm -10mm -10mm" --outfile $@ $*.pdf

%.2up: %.ps
	psnup -2 $< > $@

%.4up: %.ps
	psnup -4 $< > $@

%.6up: %.ps
	psnup -6 $< > $@

%.8up: %.ps
	psnup -8 $< > $@

#
# Use XFIG to generate separate pdf/latex
#
%.pdftex: %.fig
	fig2dev -L pdftex   -m 0.9 $< $*.pdf
	fig2dev -L pdftex_t -m 0.9 $< $@

%.pdf: %.fig
	fig2dev -L pdf $< $@

#
# Use XFIG and fig2mpdf to generate spearte fig builds based on the
# depths of the elements in the figure.
#
%-0.pdf: %.fig
	fig2mpdf -l -m $<
	mv $(subst -0.pdf,-*.pdf, $(notdir $@)) $(dir $@)

#
# DVI -> PS -> PDF
#
#%.ps: %.dvi
#	dvips -Pcmz -t a4 $* -o
#
#%.pdf: %.ps
#	ps2pdf -sPAPERSIZE=a4 \
#	 -dAutoFilterColorImages=false \
#	 -dColorImageFilter=/FlateEncode \
#	 -dAutoFilterGrayImages=false \
#	 -dGrayImageFilter=/FlateEncode \
#	 $^ $@
#
# BEAMER: slides are rotated, etc. so do some special processing
#
# %-2x2.pdf == PDF 4 slides per page
#
%.8bup: %.ps
	pstops '8:0@0.6(0,.55h)+2@.6(0,.325h)+4@.6(0,.1h)+6@.6(0,-.125h)+1@.6(.4w,.55h)+3@.6(.4w,.325h)+5@.6(.4w,.1h)+7@.6(.4w,-.125h)' $< $@
%.8bpdf: %.8bup
	ps2pdf $< $@
%-8bup.pdf: %.8bpdf
	mv $< $@

%.6bup: %.ps
	pstops '6:0@0.6(0,.55h)+2@.6(0,.225h)+4@.6(0,-.125h)+1@.6(.4w,.55h)+3@.6(.4w,.225h)+5@.6(.4w,-.125h)' $< $@
%.6bpdf: %.6bup
	ps2pdf $< $@
%-6bup.pdf: %.6bpdf
	mv $< $@

%.4bup: %.ps
	pstops '4:0@0.9R(.1w,1.05h)+2@0.9R(-.35w,1.05h)+1@0.9R(.1w,.6h)+3@0.9R(-.35w,.6h)' $< $@
%.4bpdf: %.4bup
	ps2pdf $< $@
%-2x2.pdf: %.pdf
	pdfnup --nup 2x2 $^
%-2x4.pdf: %.pdf
	pdfnup --nup 2x4 $^

graphics/%.pdf: graphics/%.gnuplot
	gnuplot $^
	epstopdf $*.eps --outfile=graphics/$*.pdf
	rm -f $*.eps

clean::
	rm -f *.aux *.dvi *.dep *.log *.out *.blg *.snm *.vrb
	rm -f *.tok *.toc *.lof *.lot *.lol *.idx *.ilg *.ind *.nav
	rm -f *~ *.bak _region_.tex

realclean:: clean
	rm -f $(APP).pdf *.aux *.bbl *.brf 
	rm -f *-[1234]x[1234].pdf
	rm -f *.[2468][lb]up *.[2468]up *.[2468][lb]pdf *.[2468]pdf
	rm -rf $(APP).prv
	rm -rf auto/

$(APP).pdf: $(APP).tex
