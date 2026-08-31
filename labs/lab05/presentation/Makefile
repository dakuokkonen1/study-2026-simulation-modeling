OUTPUT := _output
SOURCE := simulation-modeling-lab05-presentation.qmd
FINAL := simulation-modeling-lab05-presentation.html
PPTX := simulation-modeling-lab05-presentation.pptx

.PHONY: all html verify clean

all: html verify

html:
	quarto render $(SOURCE) --to revealjs
	cp $(OUTPUT)/$(FINAL) $(FINAL)

verify:
	@test -s $(FINAL)
	@test -s $(PPTX)
	@unzip -t $(PPTX) >/dev/null

clean:
	rm -rf $(OUTPUT) .quarto
