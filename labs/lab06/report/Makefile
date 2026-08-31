SOURCE = simulation-modeling-lab06-report.qmd
DOCX = simulation-modeling-lab06-report.docx

.PHONY: all docx pdf
all: docx pdf
docx:
	quarto render $(SOURCE) --to docx
pdf: docx
	libreoffice -env:UserInstallation=file:///tmp/lab06-report-office --headless --convert-to pdf --outdir . $(DOCX)
