SCRIPTS = scripts/daisyworld.jl scripts/daisyworld-animate.jl scripts/daisyworld-count.jl scripts/daisyworld-luminosity.jl scripts/daisyworld__param.jl scripts/daisyworld-count__param.jl scripts/daisyworld-luminosity__param.jl

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
