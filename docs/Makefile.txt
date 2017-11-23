help: generated_rsts
	python -msphinx source build

generated_rsts: source/CHARMED_batch.rst

source/CHARMED_batch.rst: ../Data/CHARMED_demo/html/CHARMED_batch.html embed_html.py
	python embed_html.py $@ $< "CHARMED *Composite Hindered and Restricted Model for Diffusion*"

.PHONY: help Makefile generated_rsts
