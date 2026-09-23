LABEL  = com.firedev.threefinger
PLIST  = $(HOME)/Library/LaunchAgents/$(LABEL).plist
BINDIR = $(shell [ -w /usr/local/bin ] && echo /usr/local/bin || echo $(HOME)/.local/bin)

# Sign with a real identity when there is one: Accessibility grants follow the
# signing identity, so upgrades keep them. Ad-hoc signing (no identity) changes
# every build and the grant goes stale.
SIGN ?= $(shell security find-identity -v -p codesigning 2>/dev/null | awk -F'"' 'NR==1 && NF>1 {print $$2}')

threefinger: main.swift mt.h
	swiftc -O -import-objc-header mt.h -o threefinger main.swift
	$(if $(SIGN),codesign -f -s "$(SIGN)" -i $(LABEL) threefinger)

run: threefinger
	./threefinger --debug

install: threefinger
	-launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null
	-launchctl bootout gui/$$(id -u)/homebrew.mxcl.threefinger 2>/dev/null
	-launchctl bootout gui/$$(id -u)/sh.brew.threefinger 2>/dev/null
	-brew services stop threefinger 2>/dev/null
	mkdir -p $(BINDIR)
	install -m 755 threefinger $(BINDIR)/threefinger
	sed 's|/usr/local/bin|$(BINDIR)|' $(LABEL).plist > $(PLIST)
	launchctl bootstrap gui/$$(id -u) $(PLIST)
	@printf '\nInstalled: $(BINDIR)/threefinger\n\n'
	@printf 'Permissions:\n'
	@$(BINDIR)/threefinger --check --open || true
	@printf '\nNext:\n'
	@printf '  1. Allow threefinger in System Settings (Accessibility / Device Control and Data Access + Input Monitoring)\n'
	@printf '     — for threefinger itself, not Terminal.\n'
	@printf '     After reinstall: the old entry is stale even if on — remove it (−), then + the binary\n'
	@printf '  2. Trackpad → More Gestures\n'
	@printf '       Swipe between full-screen applications → Swipe Left or Right with Four Fingers\n'
	@printf '       Swipe between pages → Off  (optional)\n\n'
	@printf 'Then three fingers left/right change tabs.\n'
	@printf 'Optional: keep Mission Control / App Exposé on three fingers (up all windows · down this app).\n\n'

uninstall:
	-launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null
	rm -f $(PLIST) $(BINDIR)/threefinger

clean:
	rm -f threefinger threefinger-arm64.tar.gz

release: threefinger
	tar czf threefinger-arm64.tar.gz threefinger $(LABEL).plist
	gh release upload "$$(gh release view --json tagName -q .tagName)" threefinger-arm64.tar.gz --clobber

.PHONY: run install uninstall clean release
