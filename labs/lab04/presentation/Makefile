OUTPUT := _output
SOURCE := simulation-modeling-lab04-presentation.qmd
FINAL := simulation-modeling-lab04-presentation.html
FINAL_PDF := simulation-modeling-lab04-presentation.pdf

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
