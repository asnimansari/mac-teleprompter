APP := build/MacTeleprompter.app

.PHONY: build run clean

build:
	swift build -c release
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/MacTeleprompter $(APP)/Contents/MacOS/
	cp Support/Info.plist $(APP)/Contents/
	codesign --force --sign - $(APP)

run: build
	-pkill -x MacTeleprompter
	open $(APP)

clean:
	rm -rf .build build
