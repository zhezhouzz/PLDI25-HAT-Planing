# create pdf

.PHONY: clouseau

all: clouseau

clouseau: main.tex \
	commands.sty refinementtydef.sty
	pdflatex -jobname="clouseau" -shell-escape main
	bibtex clouseau
	clear
	pdflatex -jobname="clouseau" -shell-escape main
	clear
	pdflatex -jobname="clouseau" -shell-escape main

# create pdf without bibs (fast)
haste:
	pdflatex -shell-escape main

# remove tex objects
clean:
	rm -f *.log *.aux *.blg *.bbl *.out *~ *.cut sections/*.aux sections/tech/*.aux

# remove objects, including the pdf file
cleanall:
	 rm -f *.log *.aux *.blg *.bbl *.out *~ *.cut sections/*.aux sections/tech/*.aux *.pdf
