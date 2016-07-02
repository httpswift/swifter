//
//  HttpHandlers+Scopes.swift
//  Swifter
//
//  Copyright © 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension HttpHandlers {
    
    public class func scopes(_ scope: Scope) -> ((HttpRequest) -> HttpResponse) {
        return { r in
            bufferToken = ""
            scope()
            return .RAW(200, "OK", ["Content-Type": "text/html"], { $0.write([UInt8](("<!DOCTYPE html>" + bufferToken).utf8)) })
        }
    }
}

public var src    : String? = nil
public var style  : String? = nil
public var width  : String? = nil
public var height : String? = nil
public var inner  : String? = nil
public var ref    : String? = nil
public var href   : String? = nil
public var type   : String? = nil

private func scopesPushAttributes() {
    attributesStack.append(["src": src, "style": style, "width": width, "height": height, "inner": inner, "ref": ref, "href": href, "type": type])
    src = nil
    style = nil
    width = nil
    height = nil
    inner = nil
    ref = nil
    href = nil
    type = nil
}

private func scopesPopAttributes() {
    if let last = attributesStack.last {
        src = last["src"]!
        style = last["style"]!
        width = last["width"]!
        height = last["height"]!
        inner = last["inner"]!
        ref = last["ref"]!
        href = last["href"]!
        type = last["type"]!
        attributesStack.removeLast()
    }
}

public var attributesStack = [[String: String?]]()

var bufferToken = ""

public typealias Scope = (Void) -> Void

public func element( _ node: String, attrs: [String: String?] = [:], scope: Scope) {
    
    scopesPushAttributes()
    
    bufferToken = bufferToken + "<" + node
    
    var bufferClone = bufferToken
    bufferToken = ""
    
    scope()
    
    var mergedAttributes = [String: String?]()
    for item in ["src": src, "style": style, "width": width, "height": height, "ref": ref, "href": href, "type": type].enumerated() {
        mergedAttributes.updateValue(item.element.value, forKey: item.element.key)
    }
    for item in attrs.enumerated() {
        mergedAttributes.updateValue(item.element.value, forKey: item.element.key)
    }
    
    bufferClone = bufferClone + mergedAttributes.reduce("") {
        if let value = $0.1.value {
            return $0.0 + " \($0.1.key)=\"\(value)\""
        } else {
            return $0.0
        }
    }
    
    bufferToken = bufferClone + ">" + (inner ?? bufferToken) + "</" + node + ">"
    
    scopesPopAttributes()
}

public func a(scope: Scope) { element("a", scope: scope) }
public func p(scope: Scope) { element("p", scope: scope) }
public func u(scope: Scope) { element("u", scope: scope) }
public func b(scope: Scope) { element("b", scope: scope) }

public func br(scope: Scope) { element("br", scope: scope) }
public func hr(scope: Scope) { element("hr", scope: scope) }
public func h1(scope: Scope) { element("h1", scope: scope) }
public func h2(scope: Scope) { element("h2", scope: scope) }
public func h3(scope: Scope) { element("h3", scope: scope) }
public func h4(scope: Scope) { element("h4", scope: scope) }
public func h5(scope: Scope) { element("h5", scope: scope) }
public func td(scope: Scope) { element("td", scope: scope) }
public func tr(scope: Scope) { element("tr", scope: scope) }
public func li(scope: Scope) { element("li", scope: scope) }
public func ul(scope: Scope) { element("ul", scope: scope) }

public func div(scope: Scope) { element("div", scope: scope) }
public func img(scope: Scope) { element("img", scope: scope) }
public func big(scope: Scope) { element("big", scope: scope) }
public func nav(scope: Scope) { element("nav", scope: scope) }

public func html(scope: Scope) { element("html", scope: scope) }
public func meta(scope: Scope) { element("meta", scope: scope) }
public func head(scope: Scope) { element("head", scope: scope) }
public func body(scope: Scope) { element("body", scope: scope) }
public func span(scope: Scope) { element("span", scope: scope) }
public func form(scope: Scope) { element("form", scope: scope) }
public func link(scope: Scope) { element("link", scope: scope) }

public func table(scope: Scope) { element("table", scope: scope) }
public func tbody(scope: Scope) { element("tbody", scope: scope) }
public func small(scope: Scope) { element("small", scope: scope) }
public func input(scope: Scope) { element("input", scope: scope) }
public func label(scope: Scope) { element("label", scope: scope) }
public func video(scope: Scope) { element("video", scope: scope) }
public func style(scope: Scope) { element("style", scope: scope) }
public func title(scope: Scope) { element("title", scope: scope) }

public func header(scope: Scope) { element("header", scope: scope) }
public func footer(scope: Scope) { element("footer", scope: scope) }
public func iframe(scope: Scope) { element("iframe", scope: scope) }
public func strong(scope: Scope) { element("strong", scope: scope) }
public func option(scope: Scope) { element("option", scope: scope) }
public func center(scope: Scope) { element("center", scope: scope) }
public func object(scope: Scope) { element("object", scope: scope) }

public func script(scope: Scope) { element("script", scope: scope) }
public func canvas(scope: Scope) { element("canvas", scope: scope) }

public func textarea(scope: Scope) { element("textarea", scope: scope) }

public func stylesheet(scope: Scope) { element("link", attrs: ["rel": "stylesheet", "type": "text/css"], scope: scope) }
