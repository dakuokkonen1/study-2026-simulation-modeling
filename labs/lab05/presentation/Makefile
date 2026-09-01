OUTPUT := _output
SOURCE := simulation-modeling-lab05-presentation.qmd
FINAL := simulation-modeling-lab05-presentation.html
PDF := simulation-modeling-lab05-presentation.pdf

.PHONY: all html verify clean

all: html verify

html:
	quarto render $(SOURCE) --to revealjs
	cp $(OUTPUT)/$(FINAL) $(FINAL)

verify:
	@test -s $(FINAL)
	@test -s $(PDF)

clean:
	rm -rf $(OUTPUT) .quarto
