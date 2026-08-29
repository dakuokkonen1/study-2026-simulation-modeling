OUTPUT := _output
SOURCE := simulation-modeling-lab01-presentation.qmd
FINAL := simulation-modeling-lab01-presentation.html

.PHONY: all html verify clean

all: html verify

html:
	quarto render $(SOURCE) --to revealjs
	cp $(OUTPUT)/$(FINAL) $(FINAL)

verify:
	@test -s $(FINAL)

clean:
	rm -rf $(OUTPUT) .quarto
