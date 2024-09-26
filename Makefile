# create pdf

.PHONY: marple

all: marple

marple: main.tex sections/intro.tex sections/overview.tex sections/lang.tex \
	sections/typing.tex sections/algo.tex sections/evaluation.tex \
	sections/related.tex sections/conclusion.tex \
	commands.sty refinementtydef.sty
	pdflatex -jobname="marple" -shell-escape main
	bibtex marple
	clear
	pdflatex -jobname="marple" -shell-escape main
	clear
	pdflatex -jobname="marple" -shell-escape main

# create pdf without bibs (fast)
haste:
	pdflatex -shell-escape main

# remove tex objects
clean:
	rm -f *.log *.aux *.blg *.bbl *.out *~ *.cut sections/*.aux sections/tech/*.aux

# remove objects, including the pdf file
cleanall:
	 rm -f *.log *.aux *.blg *.bbl *.out *~ *.cut sections/*.aux sections/tech/*.aux *.pdf
