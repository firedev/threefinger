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
	@echo ">>> Installed and loaded ($(BINDIR)/threefinger)."
	@echo ">>> Grant Accessibility to the BINARY itself: System Settings → Privacy & Security → Accessibility → + → $(BINDIR)/threefinger. Without it, swipes are detected but keys silently don't post."

uninstall:
	-launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null
	rm -f $(PLIST) $(BINDIR)/threefinger

clean:
	rm -f threefinger

.PHONY: run install uninstall clean
