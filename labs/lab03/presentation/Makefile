OUTPUT := _output
SOURCE := simulation-modeling-lab03-presentation.qmd
FINAL := simulation-modeling-lab03-presentation.html
FINAL_PDF := simulation-modeling-lab03-presentation.pdf

.PHONY: all html verify clean

all: html verify

html:
	quarto render $(SOURCE) --to revealjs
	cp $(OUTPUT)/$(FINAL) $(FINAL)

verify:
	@test -s $(FINAL)
	@test -s $(FINAL_PDF)

clean:
	rm -rf $(OUTPUT) .quarto
