SOURCE = simulation-modeling-lab08-presentation.qmd
HTML = simulation-modeling-lab08-presentation.html
PDF = simulation-modeling-lab08-presentation.pdf

.PHONY: all html pdf
all: html pdf
html:
	quarto render $(SOURCE) --to revealjs --embed-resources
pdf: html
	decktape reveal --chrome-path /usr/bin/chromium --chrome-arg=--no-sandbox --chrome-arg=--disable-dev-shm-usage --size 1280x720 --load-pause 5000 --pause 1500 'file://$(CURDIR)/$(HTML)' $(PDF)
