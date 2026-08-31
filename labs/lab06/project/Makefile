JULIA ?= julia
QUARTO ?= quarto
JUPYTER ?= jupyter
SCENARIOS = sirpetri_run sirpetri_scan_parameters sirpetri_animate sirpetri_report sirpetri_run__param sirpetri_scan_parameters__param sirpetri_animate__param sirpetri_report__param

.PHONY: setup run tangle notebooks docs test all
setup:
	$(JULIA) --project=. scripts/setup_environment.jl

run:
	@set -e; for name in $(SCENARIOS); do $(JULIA) --project=. scripts/$$name.jl; done

tangle:
	$(JULIA) --project=. scripts/tangle.jl

notebooks:
	@set -e; for name in $(SCENARIOS); do $(JUPYTER) nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-lab06-1.11 --ExecutePreprocessor.timeout=1800 notebooks/$$name/$$name.ipynb; $(JUPYTER) trust notebooks/$$name/$$name.ipynb; done

docs:
	@set -e; for name in $(SCENARIOS); do $(QUARTO) render markdown/$$name/$$name.qmd --to html --embed-resources; done

test:
	$(JULIA) --project=. test/runtests.jl

all: setup tangle run notebooks docs test
