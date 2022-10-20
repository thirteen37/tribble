.PHONY: run build clean

run: build
	open tribble.pdx

build: tribble.pdx

clean:
	rm -rf tribble.pdx

%.pdx: source/*.lua
	pdc source $@
