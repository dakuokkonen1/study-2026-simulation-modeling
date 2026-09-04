JULIA ?= julia
JUPYTER ?= jupyter
QUARTO ?= quarto
SCENARIOS = sir_des sir_des__param sir_duration sir_benchmark sir_csv_report sir_demography sir_vaccination sir_seir sir_compare_ode

.PHONY: setup run tangle notebooks docs test all
setup:
	$(JULIA) --project=. scripts/setup_environment.jl
run:
	@set -e; for name in $(SCENARIOS); do $(JULIA) --project=. scripts/$$name.jl; done
tangle:
	$(JULIA) --project=. scripts/tangle.jl
notebooks:
	@set -e; for name in $(SCENARIOS); do $(JUPYTER) nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-lab08-1.11 --ExecutePreprocessor.timeout=7200 notebooks/$$name/$$name.ipynb; $(JUPYTER) trust notebooks/$$name/$$name.ipynb; done
docs:
	@set -e; for name in $(SCENARIOS); do (cd notebooks/$$name && $(QUARTO) render $$name.ipynb --to html --embed-resources --no-execute); mv notebooks/$$name/$$name.html markdown/$$name/$$name.html; done
test:
	$(JULIA) --project=. test/runtests.jl
all: setup tangle run notebooks docs test
