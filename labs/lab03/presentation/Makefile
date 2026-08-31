OUTPUT := _output
SOURCE := simulation-modeling-lab03-presentation.qmd
FINAL := simulation-modeling-lab03-presentation.html
FINAL_PPTX := simulation-modeling-lab03-presentation.pptx

.PHONY: all html verify clean

all: html verify

html:
	quarto render $(SOURCE) --to revealjs
	cp $(OUTPUT)/$(FINAL) $(FINAL)

verify:
	@test -s $(FINAL)
	@test -s $(FINAL_PPTX)

clean:
	rm -rf $(OUTPUT) .quarto
