all : old_bailey.pdf
.PHONY : all



NUWEB=/usr/local/bin/nuweb
.SUFFIXES: .pdf .w .tex .html .aux .log .php

FIGFILES=fileschema

FIGFILENAMES=$(foreach fil,$(FIGFILES), $(fil).fig)
PDFT_NAMES=$(foreach fil,$(FIGFILES), $(fil).pdftex_t)
PDF_FIG_NAMES=$(foreach fil,$(FIGFILES), $(fil).pdftex)
PST_NAMES=$(foreach fil,$(FIGFILES), $(fil).pstex_t)
PS_FIG_NAMES=$(foreach fil,$(FIGFILES), $(fil).pstex)

W2PDF=../nuweb/bin/w2pdf
HTML_PS_FIG_NAMES=$(foreach fil,$(FIGFILES), m4_htmldocdir/$(fil).pstex)
HTML_PST_NAMES=$(foreach fil,$(FIGFILES), m4_htmldocdir/$(fil).pstex_t)
MKDIR = mkdir -p

 

%.eps: %.fig
	fig2dev -L eps $< > $@

%.pstex: %.fig
	fig2dev -L pstex $< > $@

.PRECIOUS : %.pstex
%.pstex_t: %.fig %.pstex
	fig2dev -L pstex_t -p $*.pstex $< > $@

%.pdftex: %.fig
	fig2dev -L pdftex $< > $@

.PRECIOUS : %.pdftex
%.pdftex_t: %.fig %.pstex
	fig2dev -L pdftex_t -p $*.pdftex $< > $@

%.pdf : %.w $(W2PDF)  $(PDF_FIG_NAMES) $(PDFT_NAMES)
	chmod 775 $(W2PDF)
	$(W2PDF) $*

m4_htmldocdir/%.pstex : %.pstex
	cp  $< $@

m4_htmldocdir/%.pstex_t : %.pstex_t
	cp  $< $@


m4_old_bailey.w : a_old_bailey.w
	gawk '{if(match($$0, "@%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_old_bailey.w \
          | gawk '{gsub(/[\\][\$$]/, "$$");print}'  > m4_old_bailey.w

old_bailey.w : m4_old_bailey.w
	m4 -P m4_old_bailey.w > old_bailey.w

bibfile : old_bailey.aux /home/paul/bin/mkportbib
	/home/paul/bin/mkportbib old_bailey litprog

.PHONY : bibfile
$(W2PDF) : old_bailey.w
	$(NUWEB) old_bailey.w
html/old_bailey.nw : old_bailey.w
	cp  old_bailey.w html/old_bailey.nw

m4_4htfildest : m4_4htfilsource
	cp m4_4htfilsource m4_4htfildest

m4_htmlbibfil : m4_anuwebdir/old_bailey.bib
	cp m4_anuwebdir/old_bailey.bib m4_htmlbibfil

html/old_bailey.html : html/old_bailey.nw m4_4htfildest $(HTML_PS_FIG_NAMES) $(HTML_PST_NAMES) m4_htmlbibfil
	cp w2html /bin
	cd /bin && chmod 775 w2html
	cd m4_htmldocdir && /bin/w2html old_bailey.w


pdf : old_bailey.pdf

print : old_bailey.pdf
	lpr old_bailey.pdf

view : old_bailey.pdf
	evince old_bailey.pdf

html : html/old_bailey.html

DIRS = ../nuweb/bin 

$(DIRS) : 
	$(MKDIR) $@

sources : old_bailey.w $(DIRS)
	$(NUWEB) old_bailey.w


