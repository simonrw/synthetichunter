HELPTEXT = "\
		   \n Allowed commands: 			\
		   \n 	- server					\
		   \n		Runs a node server		\
		   \n								\
		   \n	- coffee					\
		   \n		Compiles coffeescript	\
		   \n								\
		   \n	-deps						\
		   \n		Installs dependencies	\
		   \n\n								\
		   "

.PHONY: server coffee deps help

all: | coffee server

server:
	@echo "Running server"
	@node app.js

coffee: 
	@echo "Compiling coffeescript files"
	@coffee --compile --output . coffee

deps:
	@echo "Fetching dependencies"
	@LINK=g++ npm install

help:
	@echo $(HELPTEXT)
