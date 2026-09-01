SOURCE = simulation-modeling-lab06-presentation.qmd
PDF = simulation-modeling-lab06-presentation.pdf

.PHONY: all html verify
all: html verify
html:
	quarto render $(SOURCE) --to revealjs --embed-resources
verify:
	@test -s $(PDF)
