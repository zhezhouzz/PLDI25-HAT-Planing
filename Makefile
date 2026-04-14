.PHONY: haste all clean cleanall nocite clouseau camera-ready

DEPS = main.tex bibliography.bib commands.sty refinementtydef.sty \
	sections/0-intro.tex sections/1-overview.tex sections/2-language.tex \
	sections/3-algo.tex sections/4-evaluation.tex sections/5-related.tex \
	tech/outlines.tex tech/0-semantics.tex tech/1-typing.tex tech/2-denotation.tex \
	tech/3-algo.tex tech/4-proof-0.tex tech/5-explanation.tex tech/6-evaluation.tex

CAMERA_READY_ROOT_FILES = main.tex bibliography.bib commands.sty \
	refinementtydef.sty spacingtricks.sty acmart.cls ACM-Reference-Format.bst

CAMERA_READY_SECTION_FILES = sections/0-intro.tex sections/1-overview.tex \
	sections/2-language.tex sections/3-algo.tex sections/4-evaluation.tex \
	sections/5-related.tex

CAMERA_READY_FIGURE_FILES = figures/clouseau-workflow.drawio.png \
	figures/syn-gen.drawio.png

all: clouseau.pdf clouseau-diff.pdf clouseau-sm-full.pdf

clouseau: clouseau.pdf

clouseau.pdf: $(DEPS)
	pdflatex -jobname="clouseau" -shell-escape main
	bibtex clouseau
	pdflatex -jobname="clouseau" -shell-escape main
	pdflatex -jobname="clouseau" -shell-escape main

main.bbl: $(DEPS)
	pdflatex -shell-escape main
	bibtex main

camera-ready: clouseau.pdf main.bbl
	rm -rf camera-ready camera-ready-sources.zip
	mkdir -p camera-ready/sections
	cp $(CAMERA_READY_ROOT_FILES) camera-ready/
	cp $(CAMERA_READY_SECTION_FILES) camera-ready/sections/
	mkdir -p camera-ready/figures
	cp $(CAMERA_READY_FIGURE_FILES) camera-ready/figures/
	cp main.bbl camera-ready/
	cd camera-ready && zip -r ../camera-ready-sources.zip . -x "*.DS_Store"

clouseau-diff.pdf: $(DEPS)
	pdflatex -jobname="clouseau-diff" -shell-escape "\def\diffmode{}\input main.tex"
	bibtex clouseau-diff
	pdflatex -jobname="clouseau-diff" -shell-escape "\def\diffmode{}\input main.tex"
	pdflatex -jobname="clouseau-diff" -shell-escape "\def\diffmode{}\input main.tex"

clouseau-sm-full.pdf: $(DEPS)
	pdflatex -jobname="clouseau-sm-full" -shell-escape "\def\showappendix{true}\input main.tex"
	bibtex clouseau-sm-full
	pdflatex -jobname="clouseau-sm-full" -shell-escape "\def\showappendix{true}\input main.tex"
	pdflatex -jobname="clouseau-sm-full" -shell-escape "\def\showappendix{true}\input main.tex"

clouseau-sm-techreport.pdf: $(DEPS)
	pdflatex -jobname="clouseau-sm-techreport" -shell-escape "\def\techreportmode{true}\def\showappendix{true}\input main.tex"
	bibtex clouseau-sm-techreport
	pdflatex -jobname="clouseau-sm-techreport" -shell-escape "\def\techreportmode{true}\def\showappendix{true}\input main.tex"
	pdflatex -jobname="clouseau-sm-techreport" -shell-escape "\def\techreportmode{true}\def\showappendix{true}\input main.tex"

# create pdf without bibs (fast)
haste:
	pdflatex -jobname="clouseau" -shell-escape main

# remove tex objects
clean:
	rm -f *.log *.aux *.blg *.bbl *.out *~ *.cut sections/*.aux sections/tech/*.aux *.cb *.cb2

# remove objects, including the pdf file
cleanall:
	rm -f *.log *.aux *.blg *.bbl *.out *~ *.cut sections/*.aux sections/tech/*.aux *.cb *.cb2 *.pdf

# check for things in the bib that aren't cited/used
# and citations in the file that aren't in the bib
nocite:
	checkcites clouseau
