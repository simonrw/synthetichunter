HELPTEXT = "\
		   \n Allowed commands: 			\
		   \n 	- server					\
		   \n		Runs a node server		\
		   \n								\
		   \n	- coffee					\
		   \n		Compiles coffeescript	\
		   \n								\
		   \n	- watch						\
		   \n		Watches for changes		\
		   \n								\
		   \n	-deps						\
		   \n		Installs dependencies	\
		   \n\n								\
		   "

.PHONY: server coffee deps help

all: | deps coffee server

server:
	@echo "Running server"
	@coffee app.coffee

coffee: 
	@echo "Compiling coffeescript files"
	@coffee --compile --output . coffee

deps:
	@echo "Fetching dependencies"
	@LINK=g++ npm install

help:
	@echo $(HELPTEXT)

watch: | deps coffee
	@supervisor app.coffee

