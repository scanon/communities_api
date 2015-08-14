TOP_DIR = ../..
TOOLS_DIR = $(TOP_DIR)/tools
DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment
-include $(TOOLS_DIR)/Makefile.common

R_PATH = $(DEPLOY_RUNTIME)/lib/R/bin/R
PERL_PATH = $(DEPLOY_RUNTIME)/bin/perl
SERVICE = communities_api
SERVICE_DIR = $(TARGET)/services/$(SERVICE)
SERVICE_PORT = 7117
SERVICE_URL = http://localhost:$(SERVICE_PORT)
CLIENT_URL = http://kbase.us/services/communities/1
TPAGE_WEB_ARGS = --define cgi_dir=$(SERVICE_DIR)/api/site/CGI --define api_port=$(SERVICE_PORT)
TPAGE_CGI_ARGS = --define api_dir=$(SERVICE_DIR)/api --define perl_path=$(PERL_PATH)
TPAGE_LIB_ARGS = --define api_dir=$(SERVICE_DIR)/api --define r_path=$(R_PATH)
TPAGE := $(shell which tpage)

# NOTE: stop nginx if running before make && make deploy

# things needed for testing
TESTS = $(wildcard test/script-tests/test_*.t)

default: build-tools build-scripts |

deploy: deploy-cfg | deploy-service deploy-client deploy-docs
	@echo "stoping apache ..."
	$(SERVICE_DIR)/stop_service

deploy-all: deploy

all: deploy

clean:
	$(eval AUTO_SCRIPTS = $(wildcard api-scripts/*.pl))
	for ac in $(AUTO_SCRIPTS); do \
		base=`basename $$ac`; \
		rm -f api-scripts/$$base; \
		rm -f scripts/$$base; \
	done
	$(eval TOOL_SCRIPTS = $(wildcard tools/tools/bin/*))
	for tc in $(TOOL_SCRIPTS); do \
		base=`basename $$tc`; \
		rm -f scripts/$$base; \
	done
	$(eval TOOL_LIBS = $(wildcard tools/tools/lib/*))
	for tl in $(TOOL_LIBS); do \
		base=`basename $$tl`; \
		rm -f lib/$$base; \
	done
	-rm -rf api
	-rm -rf tools
	-rm -f lib/C*
	-rm -f docs/C*
	@echo "All clean"

uninstall: clean
	$(SERVICE_DIR)/stop_service || echo "Ignore"
	-rm -rf $(SERVICE_DIR)
	@echo "Uninstall sucessful"

deploy-client: deploy-scripts | build-libs deploy-libs
	echo $(SRC_PERL)
	-mkdir -p $(SERVICE_DIR)
	@echo "client tools deployed"

deploy-service: build-service
	-mkdir -p $(SERVICE_DIR)
	-mkdir -p $(SERVICE_DIR)/conf
	cp -vR api $(SERVICE_DIR)/.
	$(TPAGE) --define target=$(TARGET) service/start_service.tt > $(SERVICE_DIR)/start_service
	cp service/stop_service $(SERVICE_DIR)/stop_service
	chmod +x $(SERVICE_DIR)/start_service
	chmod +x $(SERVICE_DIR)/stop_service
	$(TPAGE) $(TPAGE_WEB_ARGS) config/apache.conf.tt > $(BUILDROOT)/etc/apache2/sites-available/default
	$(TPAGE) $(TPAGE_WEB_ARGS) config/httpd.conf.tt > $(SERVICE_DIR)/conf/httpd.conf
	@echo "restarting apache ..."
	chmod +x $(SERVICE_DIR)/start_service
	$(SERVICE_DIR)/stop_service || echo "Ignore"
	$(SERVICE_DIR)/start_service
	@echo "service api deployed"

build-service:
	@echo "retrieving API code"
	-rm -rf api
	git submodule init api
	git submodule update api
	cd api; git pull origin shock
	cd api; make
	-rm -f api/site/lib/MGRAST/resources/m5nr.pm
	-rm -f api/site/CGI/*.cgi
	$(TPAGE) $(TPAGE_LIB_ARGS) config/Conf.pm.tt > api/conf/Conf.pm
	sed '1d' api/src/MGRAST/cgi/api.cgi | cat config/header.tt - | $(TPAGE) $(TPAGE_CGI_ARGS) > api/site/CGI/api.cgi
	chmod +x api/site/CGI/api.cgi
	@echo "done building API"

build-libs:
	api2js -url $(CLIENT_URL) -outfile docs/CommunitiesAPI.json
	definition2typedef -json docs/CommunitiesAPI.json -typedef docs/CommunitiesAPI.typedef -service CommunitiesAPI
	compile_typespec --impl CommunitiesAPI --js CommunitiesAPI --py CommunitiesAPI docs/CommunitiesAPI.typedef lib
	@echo "done building typespec libs"

build-tools:
	@echo "building API tools"
	-rm -rf tools
	git submodule init tools
	git submodule update tools

build-scripts:
	@echo "retrieving API tools"
	cp tools/tools/lib/* lib/.
	cp tools/tools/bin/mg-* scripts/.
	cp tools/tools/bin/jsonviewer.py scripts/mg-jsonviewer.py
	@echo "auto-generating API scripts"
	generate_commandline -template $(TOP_DIR)/template/communities.template -config config/commandline.conf -outdir api-scripts
	cp api-scripts/* scripts/.
	@echo "done building command line scripts"

update-tools:
	@echo "updating API tools"
	cd tools; git pull origin master

build-docs:
	api2html -url $(CLIENT_URL) -site_name "Communities API" -outfile docs/communities-api.html
	pod2html --infile=lib/CommunitiesAPIClient.pm --outfile=docs/CommunitiesAPI.html --title="Communities API Client"

deploy-docs: build-docs
	-mkdir -p $(SERVICE_DIR)/webroot
	cp docs/*.html $(SERVICE_DIR)/webroot/.
	cp docs/*.html $(SERVICE_DIR)/api/site/CGI/.
	-ln -s $(SERVICE_DIR)/api/site/CGI/communities-api.html $(SERVICE_DIR)/api/site/CGI/api.html

test: test-client

test-client:
	for t in $(TESTS); do \
		echo $$t; \
		$(KB_RUNTIME)/bin/perl $$t; \
		if [ $$? -ne 0 ]; then \
			exit 1; \
		fi \
	done

-include $(TOOLS_DIR)/Makefile.common.rules
