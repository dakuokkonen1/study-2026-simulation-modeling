JULIA ?= julia
QUARTO ?= quarto
JUPYTER ?= jupyter

.PHONY: setup tangle run notebooks docs test all

setup:
	$(JULIA) --project=. scripts/setup_environment.jl

tangle:
	$(JULIA) --project=. scripts/tangle.jl scripts/01_dining_philosophers.jl
	$(JULIA) --project=. scripts/tangle.jl scripts/02_parameter_scan.jl

run:
	$(JULIA) --project=. scripts/01_dining_philosophers.jl
	$(JULIA) --project=. scripts/02_parameter_scan.jl
	$(JULIA) --project=. scripts/03_marking_animation.jl

notebooks:
	$(JUPYTER) nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-lab05-1.11 --ExecutePreprocessor.timeout=900 notebooks/01_dining_philosophers/01_dining_philosophers.ipynb
	$(JUPYTER) nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-lab05-1.11 --ExecutePreprocessor.timeout=900 notebooks/02_parameter_scan/02_parameter_scan.ipynb

docs:
	$(QUARTO) render markdown/01_dining_philosophers/01_dining_philosophers.qmd --to html --embed-resources
	$(QUARTO) render markdown/02_parameter_scan/02_parameter_scan.qmd --to html --embed-resources

test:
	$(JULIA) --project=. test/runtests.jl

all: tangle run notebooks docs test
