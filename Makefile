LABEL  = com.firedev.threefinger
PLIST  = $(HOME)/Library/LaunchAgents/$(LABEL).plist
BINDIR = $(shell [ -w /usr/local/bin ] && echo /usr/local/bin || echo $(HOME)/.local/bin)

threefinger: main.swift mt.h
	swiftc -O -import-objc-header mt.h -o threefinger main.swift

run: threefinger
	./threefinger -v

install: threefinger
	-launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null
	mkdir -p $(BINDIR)
	cp threefinger $(BINDIR)/threefinger
	sed 's|/usr/local/bin|$(BINDIR)|' $(LABEL).plist > $(PLIST)
	launchctl bootstrap gui/$$(id -u) $(PLIST)
	@printf '\nInstalled: $(BINDIR)/threefinger\n\n'
	@printf 'Permissions:\n'
	@$(BINDIR)/threefinger --check --open || true
	@printf '\nNext:\n'
	@printf '  1. If Accessibility / Input Monitoring is MISSING above — add:\n'
	@printf '       $(BINDIR)/threefinger\n'
	@printf '     (after every reinstall: remove (−) first, then re-add;\n'
	@printf '      toggling the switch is not enough)\n'
	@printf '  2. Trackpad → More Gestures (opened when Accessibility is granted)\n'
	@printf '       Swipe between pages                     → Off\n'
	@printf '       Swipe between full-screen applications  → Swipe Left or Right with Four Fingers\n\n'
	@printf 'Default: 3-finger swipe ←/→ switches tabs (⌃⇧Tab / ⌃Tab)\n'
	@printf 'Config:  ~/.config/threefinger.json\n\n'

uninstall:
	-launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null
	rm -f $(PLIST) $(BINDIR)/threefinger

clean:
	rm -f threefinger threefinger-arm64.tar.gz

release: threefinger
	tar czf threefinger-arm64.tar.gz threefinger $(LABEL).plist
	gh release upload "$$(gh release view --json tagName -q .tagName)" threefinger-arm64.tar.gz --clobber

.PHONY: run install uninstall clean release
