.PHONY: setup tangle run notebooks docs test all

setup:
	julia --project=. scripts/setup_environment.jl

tangle:
	julia --project=. scripts/tangle.jl scripts/01_mm1_queue.jl
	julia --project=. scripts/tangle.jl scripts/02_load_scan.jl

run:
	julia --project=. scripts/01_mm1_queue.jl
	julia --project=. scripts/02_load_scan.jl

notebooks:
	jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-lab03-1.11 --ExecutePreprocessor.timeout=900 notebooks/01_mm1_queue/01_mm1_queue.ipynb
	jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-lab03-1.11 --ExecutePreprocessor.timeout=900 notebooks/02_load_scan/02_load_scan.ipynb

docs: notebooks
	quarto render notebooks/01_mm1_queue/01_mm1_queue.ipynb --to html --embed-resources --no-execute
	mv notebooks/01_mm1_queue/01_mm1_queue.html markdown/01_mm1_queue/01_mm1_queue.html
	quarto render notebooks/02_load_scan/02_load_scan.ipynb --to html --embed-resources --no-execute
	mv notebooks/02_load_scan/02_load_scan.html markdown/02_load_scan/02_load_scan.html

test:
	julia --project=. test/runtests.jl

all: tangle run notebooks docs test
