OUTPUT := _output
SOURCE := simulation-modeling-lab02-presentation.qmd
FINAL_HTML := simulation-modeling-lab02-presentation.html
FINAL_PDF := simulation-modeling-lab02-presentation.pdf

.PHONY: all html verify clean

all: html verify

html:
	quarto render $(SOURCE) --to revealjs
	cp $(OUTPUT)/$(FINAL_HTML) $(FINAL_HTML)

verify:
	@test -s $(FINAL_HTML)
	@test -s $(FINAL_PDF)

clean:
	rm -rf $(OUTPUT) .quarto
