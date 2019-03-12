import XCTest

extension MimeTypeTests {
    static let __allTests = [
        ("testCaseInsensitivity", testCaseInsensitivity),
        ("testCorrectTypes", testCorrectTypes),
        ("testDefaultValue", testDefaultValue),
        ("testTypeExtension", testTypeExtension),
    ]
}

extension SwifterTestsHttpParser {
    static let __allTests = [
        ("testParser", testParser),
    ]
}

extension SwifterTestsHttpRouter {
    static let __allTests = [
        ("testHttpRouterEmptyTail", testHttpRouterEmptyTail),
        ("testHttpRouterHandlesOverlappingPaths", testHttpRouterHandlesOverlappingPaths),
        ("testHttpRouterMultiplePathSegmentWildcards", testHttpRouterMultiplePathSegmentWildcards),
        ("testHttpRouterPercentEncodedPathSegments", testHttpRouterPercentEncodedPathSegments),
        ("testHttpRouterSimplePathSegments", testHttpRouterSimplePathSegments),
        ("testHttpRouterSinglePathSegmentWildcard", testHttpRouterSinglePathSegmentWildcard),
        ("testHttpRouterSlashRoot", testHttpRouterSlashRoot),
        ("testHttpRouterVariables", testHttpRouterVariables),
    ]
}

extension SwifterTestsStringExtensions {
    static let __allTests = [
        ("testBASE64", testBASE64),
        ("testMiscRemovePercentEncoding", testMiscRemovePercentEncoding),
        ("testMiscReplace", testMiscReplace),
        ("testMiscTrim", testMiscTrim),
        ("testMiscUnquote", testMiscUnquote),
        ("testSHA1", testSHA1),
    ]
}

extension SwifterTestsWebSocketSession {
    static let __allTests = [
        ("testParser", testParser),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MimeTypeTests.__allTests),
        testCase(SwifterTestsHttpParser.__allTests),
        testCase(SwifterTestsHttpRouter.__allTests),
        testCase(SwifterTestsStringExtensions.__allTests),
        testCase(SwifterTestsWebSocketSession.__allTests),
    ]
}
#endif
