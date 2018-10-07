PACKAGE_NAME := $(shell cat info.json|jq -r .name)
VERSION_STRING := $(shell cat info.json|jq -r .version)

DATE := $(shell date '+%d. %m. %Y')

BUILD_DIR := .build
OUTPUT_NAME := $(PACKAGE_NAME)_$(VERSION_STRING)
OUTPUT_DIR := $(BUILD_DIR)/$(OUTPUT_NAME)
#CHANGELOG := changelog.txt

PKG_COPY := $(wildcard *.md) $(wildcard *.txt) $(wildcard graphics) $(wildcard locale) $(wildcard sounds)

SED_FILES := $(shell find . -iname '*.json' -type f -not -path "./.*/*") $(shell find . -iname '*.lua' -type f -not -path "./.*/*")
OUT_FILES := $(SED_FILES:%=$(OUTPUT_DIR)/%)

SED_EXPRS := -e 's/{{MOD_NAME}}/$(PACKAGE_NAME)/g'
SED_EXPRS += -e 's/{{VERSION}}/$(VERSION_STRING)/g'

all: clean package

release: clean package

package-copy: $(PKG_DIRS) $(PKG_FILES)
	mkdir -p $(OUTPUT_DIR)
ifneq ($(PKG_COPY),)
	cp -r $(PKG_COPY) $(BUILD_DIR)/$(OUTPUT_NAME)
endif

$(OUTPUT_DIR)/%.lua: %.lua
	@mkdir -p $(@D)
	@sed $(SED_EXPRS) $< > $@
	luac -p $@

$(OUTPUT_DIR)/%: %
	mkdir -p $(@D)
	sed $(SED_EXPRS) $< > $@

changelog:
	@[ -e changelog.txt ] && \
	echo Setting changelog dates. $(DATE) && \
	sed -i 's/^Date: ??????/Date: $(DATE)/' changelog.txt || \
	echo Changelog not found.

#Remove debug switches from config file if present
nodebug:
	@[ -e $(CHANGELOG) ] && \
	echo Removing debug switches from config.lua && \
	sed -i 's/^\(.*DEBUG.*=\).*/\1 false/' $(CONFIG) && \
	sed -i 's/^\(.*LOGLEVEL.*=\).*/\1 0/' $(CONFIG) && \
	sed -i 's/^\(.*loglevel.*=\).*/\1 0/' $(CONFIG) || \
	echo No Config Files

#Run luacheck on files in build directiory
check:
	@wget -q --no-check-certificate -O ./$(BUILD_DIR)/.luacheckrc https://raw.githubusercontent.com/Nexela/Factorio-luacheckrc/0.17/.luacheckrc
	@sed -i 's/\('\''\*\*\/\.\*\/\*'\''\)/--\1/' ./$(BUILD_DIR)/.luacheckrc
	@luacheck ./$(OUTPUT_DIR) -q --codes --config ./$(BUILD_DIR)/.luacheckrc

package: package-copy $(OUT_FILES) check
	cd $(BUILD_DIR) && zip -r $(OUTPUT_NAME).zip $(OUTPUT_NAME)

clean:
	rm -rf $(BUILD_DIR)
