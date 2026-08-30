OUTPUT := _output
SOURCE := simulation-modeling-lab04-report.qmd
SOFFICE ?= soffice
FINAL_DOCX := simulation-modeling-lab04-report.docx
FINAL_PDF := simulation-modeling-lab04-report.pdf

.PHONY: all docx pdf verify clean

all: docx pdf verify

docx:
	quarto render $(SOURCE) --to docx
	cp $(OUTPUT)/$(FINAL_DOCX) $(FINAL_DOCX)

pdf: docx
	$(SOFFICE) --headless --convert-to pdf --outdir $(OUTPUT) \
		$(OUTPUT)/$(FINAL_DOCX)
	cp $(OUTPUT)/$(FINAL_PDF) $(FINAL_PDF)

verify:
	@test -s $(FINAL_DOCX)
	@test -s $(FINAL_PDF)

clean:
	rm -rf $(OUTPUT) .quarto
