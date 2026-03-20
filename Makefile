.PHONY: haste all clean cleanall nocite clouseau

DEPS = main.tex bibliography.bib commands.sty refinementtydef.sty \
	sections/0-intro.tex sections/1-overview.tex sections/2-language.tex \
	sections/3-algo.tex sections/4-evaluation.tex sections/5-related.tex \
	tech/outlines.tex tech/0-semantics.tex tech/1-typing.tex tech/2-denotation.tex \
	tech/3-algo.tex tech/4-proof-0.tex tech/5-evaluation.tex

all: clouseau.pdf clouseau-diff.pdf clouseau-sm-full.pdf

clouseau: clouseau.pdf

clouseau.pdf: $(DEPS)
	pdflatex -jobname="clouseau" -shell-escape main
	bibtex clouseau
	pdflatex -jobname="clouseau" -shell-escape main
	pdflatex -jobname="clouseau" -shell-escape main

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
