SOURCE = simulation-modeling-lab07-presentation.qmd
PDF = simulation-modeling-lab07-presentation.pdf

.PHONY: all html verify
all: html verify
html:
	quarto render $(SOURCE) --to revealjs --embed-resources
verify:
	@test -s $(PDF)
