.PHONY: server coffee

server:
	@echo "Running server"
	@node app.js

coffee: 
	@echo "Compiling coffeescript files"
	@coffee --compile --output . coffee
