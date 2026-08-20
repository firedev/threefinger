threefinger: main.swift mt.h
	swiftc -O -import-objc-header mt.h -o threefinger main.swift

run: threefinger
	./threefinger

clean:
	rm -f threefinger

.PHONY: run clean
