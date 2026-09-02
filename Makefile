LABEL  = com.firedev.threefinger
PLIST  = $(HOME)/Library/LaunchAgents/$(LABEL).plist
BINDIR = $(shell [ -w /usr/local/bin ] && echo /usr/local/bin || echo $(HOME)/.local/bin)

threefinger: main.swift mt.h
	swiftc -O -import-objc-header mt.h -o threefinger main.swift

run: threefinger
	./threefinger -v

install: threefinger
	-launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null
	-launchctl bootout gui/$$(id -u)/homebrew.mxcl.threefinger 2>/dev/null
	-brew services stop threefinger 2>/dev/null
	mkdir -p $(BINDIR)
	cp threefinger $(BINDIR)/threefinger
	sed 's|/usr/local/bin|$(BINDIR)|' $(LABEL).plist > $(PLIST)
	launchctl bootstrap gui/$$(id -u) $(PLIST)
	@printf '\nInstalled: $(BINDIR)/threefinger\n\n'
	@printf 'Permissions:\n'
	@$(BINDIR)/threefinger --check --open || true
	@printf '\nNext:\n'
	@printf '  1. Allow threefinger in System Settings (Accessibility + Input Monitoring)\n'
	@printf '     — for threefinger itself, not Terminal.\n'
	@printf '     After reinstall: remove (−), then re-add $(BINDIR)/threefinger\n'
	@printf '  2. Trackpad → More Gestures\n'
	@printf '       Swipe between full-screen applications → Swipe Left or Right with Four Fingers\n'
	@printf '       Swipe between pages → Off  (optional)\n\n'
	@printf 'Then three fingers left/right switches tabs.\n\n'

uninstall:
	-launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null
	rm -f $(PLIST) $(BINDIR)/threefinger

clean:
	rm -f threefinger threefinger-arm64.tar.gz

release: threefinger
	tar czf threefinger-arm64.tar.gz threefinger $(LABEL).plist
	gh release upload "$$(gh release view --json tagName -q .tagName)" threefinger-arm64.tar.gz --clobber

.PHONY: run install uninstall clean release
