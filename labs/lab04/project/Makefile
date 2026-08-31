SCRIPTS = scripts/sir_run_basic.jl scripts/sir_scan_beta.jl scripts/sir_migration_effect.jl scripts/sir_optimize_parameters.jl scripts/sir_visualize_dynamics.jl scripts/sir_run_basic__param.jl scripts/sir_scan_beta__param.jl scripts/sir_migration_effect__param.jl scripts/sir_optimize_parameters__param.jl scripts/sir_extra_1_2_3.jl scripts/sir_extra_4_5.jl scripts/sir_extra_6.jl

.PHONY: setup run tangle notebooks docs test all

setup:
	julia --project=. scripts/setup_environment.jl

run:
	@for script in $(SCRIPTS); do julia --project=. $$script || exit $$?; done

tangle:
	julia --project=. scripts/tangle.jl $(SCRIPTS)

notebooks:
	julia --project=. scripts/tangle.jl --execute $(SCRIPTS)

docs:
	@for script in $(SCRIPTS); do name=$$(basename $$script .jl); (cd notebooks/$$name && quarto render $$name.ipynb --to html --embed-resources --no-execute --output $$name.html) || exit $$?; mv notebooks/$$name/$$name.html markdown/$$name/$$name.html; done

test:
	julia --project=. test/runtests.jl

all:
	$(MAKE) run
	$(MAKE) notebooks
	$(MAKE) docs
	$(MAKE) test
