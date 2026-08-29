.PHONY: setup tangle run notebooks docs test all clean-results

setup:
	julia --project=. scripts/setup_environment.jl

tangle:
	julia --project=. scripts/tangle.jl scripts/01_exponential_growth.jl
	julia --project=. scripts/tangle.jl scripts/02_exponential_growth.jl

run:
	julia --project=. scripts/01_exponential_growth.jl
	julia --project=. scripts/02_exponential_growth.jl

notebooks:
	jupyter nbconvert --to notebook --execute --inplace \
		--ExecutePreprocessor.kernel_name=julia-lab01-1.11 \
		--ExecutePreprocessor.timeout=600 \
		notebooks/01_exponential_growth/01_exponential_growth.ipynb
	jupyter nbconvert --to notebook --execute --inplace \
		--ExecutePreprocessor.kernel_name=julia-lab01-1.11 \
		--ExecutePreprocessor.timeout=600 \
		notebooks/02_exponential_growth/02_exponential_growth.ipynb

docs:
	quarto render markdown/01_exponential_growth/01_exponential_growth.qmd --to html --embed-resources
	quarto render markdown/02_exponential_growth/02_exponential_growth.qmd --to html --embed-resources

test:
	julia --project=. test/runtests.jl

all: tangle run notebooks docs test

clean-results:
	rm -rf data/01_exponential_growth data/02_exponential_growth
	rm -rf plots/01_exponential_growth plots/02_exponential_growth
	rm -rf notebooks/01_exponential_growth notebooks/02_exponential_growth
	rm -rf markdown/01_exponential_growth markdown/02_exponential_growth
