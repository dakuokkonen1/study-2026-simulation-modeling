ROOT := ../../..
IMAGE := simulation-modeling-lab01:1.0.0
OUTPUT := _output
SOURCE := simulation-modeling-lab01-report.qmd
SOFFICE ?= soffice
PYTHON ?= /Users/qxar/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3

.PHONY: all html docx pdf verify clean

all: html docx pdf verify

html:
	docker run --rm -v "$(abspath $(ROOT)):/workspace" -w /workspace/labs/lab01/report $(IMAGE) \
		quarto render $(SOURCE) --to html

docx:
	docker run --rm -v "$(abspath $(ROOT)):/workspace" -w /workspace/labs/lab01/report $(IMAGE) \
		quarto render $(SOURCE) --to docx
	mv $(OUTPUT)/simulation-modeling-lab01-report.docx $(OUTPUT)/simulation-modeling-lab01-report.raw.docx
	$(PYTHON) scripts/polish_docx.py \
		$(OUTPUT)/simulation-modeling-lab01-report.raw.docx \
		$(OUTPUT)/simulation-modeling-lab01-report.docx
	rm -f $(OUTPUT)/simulation-modeling-lab01-report.raw.docx

pdf: docx
	$(SOFFICE) --headless --convert-to pdf --outdir $(OUTPUT) \
		$(OUTPUT)/simulation-modeling-lab01-report.docx

verify:
	@test -s $(OUTPUT)/simulation-modeling-lab01-report.html
	@test -s $(OUTPUT)/simulation-modeling-lab01-report.docx
	@test -s $(OUTPUT)/simulation-modeling-lab01-report.pdf

clean:
	rm -rf $(OUTPUT) .quarto
