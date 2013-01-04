.PHONY: server coffee

all: | coffee server

server:
	@echo "Running server"
	@node app.js

coffee: 
	@echo "Compiling coffeescript files"
	@coffee --compile --output . coffee

deps:
	@echo "Fetching dependencies"
	@npm install
