#!/bin/bash

set -e

# Build shared library for SQLite.

echo "Building csqlite shared library...."

clang -shared ../Sources/sqlite.c -o libcsqlite.so

# Build Swifter Library

SOURCES="
	../Sources/File.swift \
	../Sources/SQLite.swift \
	../Sources/Reflection.swift \
	../Sources/Process.swift \
	../Sources/Socket.swift \
	../Sources/String+Misc.swift \
	../Sources/String+SHA1.swift \
	../Sources/String+BASE64.swift \
	../Sources/HttpRequest.swift \
	../Sources/HttpResponse.swift \
	../Sources/HttpServer.swift \
	../Sources/HttpRouter.swift \
	../Sources/HttpServerIO.swift \
	../Sources/HttpParser.swift \
	../Sources/HttpHandlers.swift \
	../Sources/HttpHandlers+Files.swift \
	../Sources/HttpHandlers+WebSockets.swift \
"

echo "Building Swifter library...."

swiftc -emit-library -module-name Swifter $SOURCES -import-objc-header ../Sources/sqlite.h -lcsqlite -L.

echo "Building Swifter module...."

swiftc -emit-module -module-name Swifter $SOURCES -import-objc-header ../Sources/sqlite.h -lcsqlite -L. -I.

echo "Done."




