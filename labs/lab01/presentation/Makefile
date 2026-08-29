ROOT := ../../..
IMAGE := simulation-modeling-lab01:1.0.0
OUTPUT := _output
SOURCE := simulation-modeling-lab01-presentation.qmd
NODE := /Users/qxar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node
ARTIFACT_TOOL_MODULE := /Users/qxar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs
SOFFICE ?= soffice

.PHONY: all html pptx pdf verify clean

all: html pptx pdf verify

html:
	docker run --rm -v "$(abspath $(ROOT)):/workspace" -w /workspace/labs/lab01/presentation $(IMAGE) \
		quarto render $(SOURCE) --to revealjs

pptx:
	ARTIFACT_TOOL_MODULE="$(ARTIFACT_TOOL_MODULE)" $(NODE) scripts/build_presentation.mjs

pdf: pptx
	$(SOFFICE) --headless --convert-to pdf --outdir $(OUTPUT) \
		$(OUTPUT)/simulation-modeling-lab01-presentation.pptx

verify:
	@test -s $(OUTPUT)/simulation-modeling-lab01-presentation.html
	@test -s $(OUTPUT)/simulation-modeling-lab01-presentation.pptx
	@test -s $(OUTPUT)/simulation-modeling-lab01-presentation.pdf
	@test -s $(OUTPUT)/presentation-montage.webp

clean:
	rm -rf $(OUTPUT) .quarto
