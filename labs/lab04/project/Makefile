.PHONY: setup tangle run notebooks docs test all

setup:
	julia --project=. scripts/setup_environment.jl

tangle:
	julia --project=. scripts/tangle.jl scripts/01_tcp_red.jl
	julia --project=. scripts/tangle.jl scripts/02_flow_scan.jl

run:
	julia --project=. scripts/01_tcp_red.jl
	julia --project=. scripts/02_flow_scan.jl

notebooks:
	jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-lab04-1.11 --ExecutePreprocessor.timeout=900 notebooks/01_tcp_red/01_tcp_red.ipynb
	jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-lab04-1.11 --ExecutePreprocessor.timeout=900 notebooks/02_flow_scan/02_flow_scan.ipynb

docs:
	quarto render markdown/01_tcp_red/01_tcp_red.qmd --to html --embed-resources
	quarto render markdown/02_flow_scan/02_flow_scan.qmd --to html --embed-resources

test:
	julia --project=. test/runtests.jl

all: tangle run notebooks docs test
