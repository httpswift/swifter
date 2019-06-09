# Changelog
All notable changes to this project will be documented in this file. Changes notes typically follow this pattern:

> **Fixed**
> * Something was fixed. (#pr-number) by @pr-author
> 
> **Changed**
> * Something was changed. (#pr-number) by @pr-author
> 
> **Added**
> * Something was added. (#pr-number) by @pr-author
> 
> **Removed**
> * Something was removed. (#pr-number) by @pr-author
> 
> **Deprecated**
> * Something was deprecated. (#pr-number) by @pr-author

# [Unreleased]

* Nothing yet.

# [1.4.7] 

## Added
- A new `CHANGELOG.md` to keep track of changes in the project. ([#385](https://github.com/httpswift/swifter/pull/385)) by [@Vkt0r](https://github.com/Vkt0r)
- Added [Danger](https://danger.systems/ruby/) and Swiftlint to the project. ([#398](https://github.com/httpswift/swifter/pull/398)) by [@Vkt0r](https://github.com/Vkt0r)
- Added the following to `Scopes`: `manifest`, `ontouchstart`, `dataText`. ([#410](https://github.com/httpswift/swifter/pull/410)) by [@apocolipse](https://github.com/apocolipse)
- Added `htmlBody(String)` to `HttpResonse`  as a compability case for the changed `html(String)` case.

## Fixed
- An issue causing a crash regarding a thread race condition. ([#399](https://github.com/httpswift/swifter/pull/399)) by [@Vkt0r](https://github.com/Vkt0r)
- An issue in the `HttpRouter` causing issues to handle routes with overlapping in the tail. ([#379](https://github.com/httpswift/swifter/pull/359), [#382](https://github.com/httpswift/swifter/pull/382)) by [@Vkt0r](https://github.com/Vkt0r)

- Fixes build errors by excluding XC(UI)Test files from regular targets [#397](https://github.com/httpswift/swifter/pull/397)) by [@ChristianSteffens](https://github.com/ChristianSteffens)
- Fixes `HttpRequest.path` value to be parsed without query parameters [#404](https://github.com/httpswift/swifter/pull/404)) by [@mazyod](https://github.com/mazyod)
- Fixes the issue of missing `Content-Length` header item when `shareFilesFromDirectory` is being used to share files [#406](https://github.com/httpswift/swifter/pull/406) by [@nichbar](https://github.com/nichbar)

## Changed
- Performance: Batch reads of websocket payloads rather than reading byte-by-byte. ([#387](https://github.com/httpswift/swifter/pull/387)) by [@lynaghk](https://github.com/lynaghk)
- Podspec source_files updated to match source file directory changes. ([#400](https://github.com/httpswift/swifter/pull/400)) by [@welsonpan](https://github.com/welsonpan)
- Refactor: Use Foundation API for Base64 encoding. ([#403](https://github.com/httpswift/swifter/pull/403)) by [@mazyod](https://github.com/mazyod)
- Refactor: Use `URLComponents` for `HttpRequest` path and query parameters parsing [#404](https://github.com/httpswift/swifter/pull/404)) by [@mazyod](https://github.com/mazyod)
- `HttpResponse` functions `statusCode()` and `reasonPhrase` changed to computed variables instead of functions, and made public (No impact on existing usage as it was previously internal). ([#410](https://github.com/httpswift/swifter/pull/410)) by [@apocolipse](https://github.com/apocolipse)
- Adjusted the associated type of enum case `HttpResponseBody.json` from `AnyObject` to `Any` to allow Swift dictionaries/arrays without converting to their Objective-C counterparts. ([#393](https://github.com/httpswift/swifter/pull/393)) by [@edwinveger](https://github.com/edwinveger)
- `HttpResponse`: `html` requires now a complete html-string, not only the body-part.
- Include the `CHANGELOG.md` and `README.md` in the Xcode-Project for easy access / changes.

## Removed
- Dropped macOS 10.9 support ([#404](https://github.com/httpswift/swifter/pull/404), [#408](https://github.com/httpswift/swifter/pull/408)) by [@mazyod](https://github.com/mazyod), [@Vkt0r](https://github.com/Vkt0r)

# [1.4.6] 
## Added
 -  The `.movedTemporarily` case (HTTP 307) to possibles HTTP responses. ([#352](https://github.com/httpswift/swifter/pull/352)) by [@csch](https://github.com/csch)
 - An example to the `README` for `"How to load HTML by string?"`. ([#352](https://github.com/httpswift/swifter/pull/352)) by [@IvanovDeveloper]( https://github.com/IvanovDeveloper)
 - CircleCI for Continous Integration in the project. ([#364](https://github.com/httpswift/swifter/pull/364)) by [@Vkt0r](https://github.com/Vkt0r)
 - Support for the Swift 5. ([#370](https://github.com/httpswift/swifter/pull/370)) by [@alanzeino](https://github.com/alanzeino)

## Changed
- The syntax to support Swift 3 and Swift 4. ([#347](https://github.com/httpswift/swifter/pull/347)) by [@fandyfyf](https://github.com/fandyfyf)
- Set to `NO` the `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` in the **tvOS** target to avoid App Store checks due to the _Frameworks_ directory. ([#361](https://github.com/httpswift/swifter/pull/361)) by [@Vkt0r](https://github.com/Vkt0r)
- The process of reading of request body and headers. ([#362](https://github.com/httpswift/swifter/pull/362)) by [@adamkaplan](https://github.com/adamkaplan)

## Fixed
- An issue in the `HttpRouter` causing issues to handle routes with overlapping. ([#359](https://github.com/httpswift/swifter/pull/359)) by [@Vkt0r](https://github.com/Vkt0r)


[Unreleased]: https://github.com/httpswift/swifter/compare/1.4.6...HEAD
[1.4.6]: https://github.com/httpswift/swifter/compare/1.4.5...1.4.6
[1.4.7]: https://github.com/httpswift/swifter/compare/1.4.6...1.4.7
