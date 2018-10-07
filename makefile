PACKAGE_NAME := $(shell cat info.json|jq -r .name)
VERSION_STRING := $(shell cat info.json|jq -r .version)

OUTPUT_NAME := $(PACKAGE_NAME)_$(VERSION_STRING)
OUTPUT_DIR := .build/$(OUTPUT_NAME)

PKG_COPY := $(wildcard *.md) graphics

SED_FILES := $(shell find . -iname '*.json' -type f -not -path "./build/*") $(shell find . -iname '*.lua' -type f -not -path "./build/*")
OUT_FILES := $(SED_FILES:%=$(OUTPUT_DIR)/%)

SED_EXPRS := -e 's/{{MOD_NAME}}/$(PACKAGE_NAME)/g'
SED_EXPRS += -e 's/{{VERSION}}/$(VERSION_STRING)/g'

all: clean package
release: clean package
package-copy: $(PKG_DIRS) $(PKG_FILES)
	mkdir -p $(OUTPUT_DIR)
ifneq ($(PKG_COPY),)
	cp -r $(PKG_COPY) build/$(OUTPUT_NAME)
endif

$(OUTPUT_DIR)/%.lua: %.lua
	@mkdir -p $(@D)
	@sed $(SED_EXPRS) $< > $@
	luac -p $@

$(OUTPUT_DIR)/%: %
	mkdir -p $(@D)
	sed $(SED_EXPRS) $< > $@

#Run luacheck on files in build directiory
check:
	@wget -q --no-check-certificate -O ./$(BUILD_DIR)/.luacheckrc https://raw.githubusercontent.com/Nexela/Factorio-luacheckrc/0.17/.luacheckrc
	@sed -i 's/\('\''\*\*\/\.\*\/\*'\''\)/--\1/' ./$(BUILD_DIR)/.luacheckrc
	@luacheck ./$(OUTPUT_DIR) -q --codes --config ./$(BUILD_DIR)/.luacheckrc

package: package-copy $(OUT_FILES) check
	cd build && zip -r $(OUTPUT_NAME).zip $(OUTPUT_NAME)

clean:
	rm -rf build/
