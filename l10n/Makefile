# Add only languages really supported by NSIS there
# For others, a PO file may be added and kept until NSIS is translated
# Languages not yet supported by NSIS: ast bn dz kk ml ta te ug vi

VPATH ?= .
MKDIR_P := mkdir -p
TEMPLATES := $(CURDIR)/templates
PO := po

DISABLED_LINGUAS=
LINGUAS= ar be bg bs ca cs da de el en eo es eu fa fi fr ga gl he hr hu is it ja ko lt nb nl pl pt pt_BR ro ru sk sl sq sr sr@latin sv th tr uk zh_CN zh_TW

all: $(TEMPLATES)/all.nsh $(TEMPLATES)/dialog.nsh $(VPATH)/$(PO)/messages.pot

$(TEMPLATES):
	$(MKDIR_P) $@

$(TEMPLATES)/dialog.nsh: win32-loader.sh $(TEMPLATES)/all.nsh | $(TEMPLATES)
	for i in $(LINGUAS) ; do \
		echo "Push \$${`LANGUAGE=$$i $< LANG_ENGLISH`}" ; \
		echo "Push \"`LANGUAGE=$$i $< English`\"" ; \
	done > $@

$(TEMPLATES)/all.nsh: $(foreach lang, $(LINGUAS), $(TEMPLATES)/$(lang).nsh) | $(TEMPLATES)
	for i in $^ ; do echo "; BEGIN $$i" ; cat $$i ; echo "; END $$i" ; done > $@

win32-loader: win32-loader.c
	gcc -DTEXTDOMAINDIR=\"$(CURDIR)/locale\" $^ -o $@

$(TEMPLATES)/en.nsh: win32-loader.sh win32-loader | $(TEMPLATES)
	LANGUAGE=C $(realpath $<) > $@

locale/%/LC_MESSAGES/win32-loader.mo: $(PO)/%.po $(VPATH)/$(PO)/messages.pot | $(TEMPLATES)
	$(MKDIR_P) locale/$*/LC_MESSAGES
	msgmerge -U $< $(dir $<)messages.pot
	msgfmt -c --statistics -o $@ $<

$(TEMPLATES)/%.nsh: win32-loader.sh win32-loader locale/%/LC_MESSAGES/win32-loader.mo | $(TEMPLATES)
	LANGUAGE=$* $(realpath $<) > $@

$(PO)/messages.pot: win32-loader.sh win32-loader.c
	xgettext --msgid-bugs-address=win32-loader@packages.debian.org --from-code=utf-8 -ctranslate --keyword=_ $^ -o $@

clean:
	rm -rf $(TEMPLATES) locale win32-loader
	rm -f $(foreach lang, $(LINGUAS), $(PO)/$(lang).po~)
