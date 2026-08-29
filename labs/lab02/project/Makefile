.PHONY: setup tangle run notebooks docs test all clean-results

setup:
	julia --project=. scripts/setup_environment.jl

tangle:
	julia --project=. scripts/tangle.jl scripts/01_sir.jl
	julia --project=. scripts/tangle.jl scripts/02_lotka_volterra.jl

run:
	julia --project=. scripts/01_sir.jl
	julia --project=. scripts/02_lotka_volterra.jl

notebooks:
	jupyter nbconvert --to notebook --execute --inplace \
		--ExecutePreprocessor.kernel_name=julia-lab02-1.11 \
		--ExecutePreprocessor.timeout=900 \
		notebooks/01_sir/01_sir.ipynb
	jupyter nbconvert --to notebook --execute --inplace \
		--ExecutePreprocessor.kernel_name=julia-lab02-1.11 \
		--ExecutePreprocessor.timeout=900 \
		notebooks/02_lotka_volterra/02_lotka_volterra.ipynb

docs:
	quarto render markdown/01_sir/01_sir.qmd --to html --embed-resources
	quarto render markdown/02_lotka_volterra/02_lotka_volterra.qmd --to html --embed-resources

test:
	julia --project=. test/runtests.jl

all: tangle run notebooks docs test

clean-results:
	rm -rf data plots notebooks markdown
