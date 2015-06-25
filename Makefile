PACKAGE = tinc
ORG = amylum

BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz

PACKAGE_VERSION = $$(awk '/^VERSION/ { print $3 }' $(BUILD_DIR)/src/Makefile)
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)

.PHONY : default submodule manual container build version push local

default: submodule container

submodule:
	git submodule update --init

manual: submodule
	./meta/launch /bin/bash || true

container:
	./meta/launch

build: submodule
	rm -rf $(BUILD_DIR)
	cp -R upstream $(BUILD_DIR)
	cd $(BUILD_DIR) && autoreconf -i && ./configure --prefix=$(RELEASE_DIR)
	make -C $(BUILD_DIR) install
	mkdir -p $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)
	cp upstream/COPYING $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)/LICENSE
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)

local: build push

