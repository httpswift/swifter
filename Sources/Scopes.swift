//
//  HttpHandlers+Scopes.swift
//  Swifter
//
//  Copyright © 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public func scopes(scope: Closure) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        ScopesBuffer[Process.TID] = ""
        scope()
        return .RAW(200, "OK", ["Content-Type": "text/html"],
                    { $0.write([UInt8](("<!DOCTYPE html>"  + (ScopesBuffer[Process.TID] ?? "")).utf8)) })
    }
}

public typealias Closure = (Void) -> Void

public var idd: String? = nil
public var dir: String? = nil
public var rel: String? = nil
public var rev: String? = nil
public var alt: String? = nil
public var forr: String? = nil
public var src: String? = nil
public var type: String? = nil
public var href: String? = nil
public var text: String? = nil
public var abbr: String? = nil
public var size: String? = nil
public var face: String? = nil
public var char: String? = nil
public var cite: String? = nil
public var span: String? = nil
public var data: String? = nil
public var axis: String? = nil
public var Name: String? = nil
public var name: String? = nil
public var code: String? = nil
public var link: String? = nil
public var lang: String? = nil
public var cols: String? = nil
public var rows: String? = nil
public var ismap: String? = nil
public var shape: String? = nil
public var style: String? = nil
public var alink: String? = nil
public var width: String? = nil
public var rules: String? = nil
public var align: String? = nil
public var frame: String? = nil
public var vlink: String? = nil
public var deferr: String? = nil
public var color: String? = nil
public var media: String? = nil
public var title: String? = nil
public var scope: String? = nil
public var classs: String? = nil
public var value: String? = nil
public var clear: String? = nil
public var start: String? = nil
public var label: String? = nil
public var action: String? = nil
public var height: String? = nil
public var method: String? = nil
public var acceptt: String? = nil
public var object: String? = nil
public var scheme: String? = nil
public var coords: String? = nil
public var usemap: String? = nil
public var onblur: String? = nil
public var nohref: String? = nil
public var nowrap: String? = nil
public var hspace: String? = nil
public var border: String? = nil
public var valign: String? = nil
public var vspace: String? = nil
public var onload: String? = nil
public var target: String? = nil
public var prompt: String? = nil
public var onfocus: String? = nil
public var enctype: String? = nil
public var onclick: String? = nil
public var onkeyup: String? = nil
public var profile: String? = nil
public var version: String? = nil
public var onreset: String? = nil
public var charset: String? = nil
public var standby: String? = nil
public var colspan: String? = nil
public var charoff: String? = nil
public var classid: String? = nil
public var compact: String? = nil
public var declare: String? = nil
public var rowspan: String? = nil
public var checked: String? = nil
public var archive: String? = nil
public var bgcolor: String? = nil
public var content: String? = nil
public var noshade: String? = nil
public var summary: String? = nil
public var headers: String? = nil
public var onselect: String? = nil
public var readonly: String? = nil
public var tabindex: String? = nil
public var onchange: String? = nil
public var noresize: String? = nil
public var disabled: String? = nil
public var longdesc: String? = nil
public var codebase: String? = nil
public var language: String? = nil
public var datetime: String? = nil
public var selected: String? = nil
public var hreflang: String? = nil
public var onsubmit: String? = nil
public var multiple: String? = nil
public var onunload: String? = nil
public var codetype: String? = nil
public var scrolling: String? = nil
public var onkeydown: String? = nil
public var maxlength: String? = nil
public var valuetype: String? = nil
public var accesskey: String? = nil
public var onmouseup: String? = nil
public var autofocus: String? = nil
public var onkeypress: String? = nil
public var ondblclick: String? = nil
public var onmouseout: String? = nil
public var httpEquiv: String? = nil
public var background: String? = nil
public var onmousemove: String? = nil
public var onmouseover: String? = nil
public var cellpadding: String? = nil
public var onmousedown: String? = nil
public var frameborder: String? = nil
public var marginwidth: String? = nil
public var cellspacing: String? = nil
public var placeholder: String? = nil
public var marginheight: String? = nil
public var acceptCharset: String? = nil

public var inner: String? = nil

public func a(c: Closure) { element("a", c) }
public func b(c: Closure) { element("b", c) }
public func i(c: Closure) { element("i", c) }
public func p(c: Closure) { element("p", c) }
public func q(c: Closure) { element("q", c) }
public func s(c: Closure) { element("s", c) }
public func u(c: Closure) { element("u", c) }

public func br(c: Closure) { element("br", c) }
public func dd(c: Closure) { element("dd", c) }
public func dl(c: Closure) { element("dl", c) }
public func dt(c: Closure) { element("dt", c) }
public func em(c: Closure) { element("em", c) }
public func hr(c: Closure) { element("hr", c) }
public func li(c: Closure) { element("li", c) }
public func ol(c: Closure) { element("ol", c) }
public func rp(c: Closure) { element("rp", c) }
public func rt(c: Closure) { element("rt", c) }
public func td(c: Closure) { element("td", c) }
public func th(c: Closure) { element("th", c) }
public func tr(c: Closure) { element("tr", c) }
public func tt(c: Closure) { element("tt", c) }
public func ul(c: Closure) { element("ul", c) }

public func ul<T: SequenceType>(collection: T, _ c: (T.Generator.Element) -> Void) {
    element("ul", {
        for item in collection {
            c(item)
        }
    })
}

public func h1(c: Closure) { element("h1", c) }
public func h2(c: Closure) { element("h2", c) }
public func h3(c: Closure) { element("h3", c) }
public func h4(c: Closure) { element("h4", c) }
public func h5(c: Closure) { element("h5", c) }
public func h6(c: Closure) { element("h6", c) }

public func bdi(c: Closure) { element("bdi", c) }
public func bdo(c: Closure) { element("bdo", c) }
public func big(c: Closure) { element("big", c) }
public func col(c: Closure) { element("col", c) }
public func del(c: Closure) { element("del", c) }
public func dfn(c: Closure) { element("dfn", c) }
public func dir(c: Closure) { element("dir", c) }
public func div(c: Closure) { element("div", c) }
public func img(c: Closure) { element("img", c) }
public func ins(c: Closure) { element("ins", c) }
public func kbd(c: Closure) { element("kbd", c) }
public func map(c: Closure) { element("map", c) }
public func nav(c: Closure) { element("nav", c) }
public func pre(c: Closure) { element("pre", c) }
public func rtc(c: Closure) { element("rtc", c) }
public func sub(c: Closure) { element("sub", c) }
public func sup(c: Closure) { element("sup", c) }

public func varr(c: Closure) { element("var", c) }
public func wbr(c: Closure) { element("wbr", c) }
public func xmp(c: Closure) { element("xmp", c) }

public func abbr(c: Closure) { element("abbr", c) }
public func area(c: Closure) { element("area", c) }
public func base(c: Closure) { element("base", c) }
public func body(c: Closure) { element("body", c) }
public func cite(c: Closure) { element("cite", c) }
public func code(c: Closure) { element("code", c) }
public func data(c: Closure) { element("data", c) }
public func font(c: Closure) { element("font", c) }
public func form(c: Closure) { element("form", c) }
public func head(c: Closure) { element("head", c) }
public func html(c: Closure) { element("html", c) }
public func link(c: Closure) { element("link", c) }
public func main(c: Closure) { element("main", c) }
public func mark(c: Closure) { element("mark", c) }
public func menu(c: Closure) { element("menu", c) }
public func meta(c: Closure) { element("meta", c) }
public func nobr(c: Closure) { element("nobr", c) }
public func ruby(c: Closure) { element("ruby", c) }
public func samp(c: Closure) { element("samp", c) }
public func span(c: Closure) { element("span", c) }
public func time(c: Closure) { element("time", c) }

public func aside(c: Closure) { element("aside", c) }
public func audio(c: Closure) { element("audio", c) }
public func blink(c: Closure) { element("blink", c) }
public func embed(c: Closure) { element("embed", c) }
public func frame(c: Closure) { element("frame", c) }
public func image(c: Closure) { element("image", c) }
public func input(c: Closure) { element("input", c) }
public func label(c: Closure) { element("label", c) }
public func meter(c: Closure) { element("meter", c) }
public func param(c: Closure) { element("param", c) }
public func small(c: Closure) { element("small", c) }
public func style(c: Closure) { element("style", c) }
public func table(c: Closure) { element("table", c) }

public func table<T: SequenceType>(collection: T, c: (T.Generator.Element) -> Void) {
    element("table", {
        for item in collection {
            c(item)
        }
    })
}

public func tbody(c: Closure) { element("tbody", c) }

public func tbody<T: SequenceType>(collection: T, c: (T.Generator.Element) -> Void) {
    element("tbody", {
        for item in collection {
            c(item)
        }
    })
}

public func tfoot(c: Closure) { element("tfoot", c) }
public func thead(c: Closure) { element("thead", c) }
public func title(c: Closure) { element("title", c) }
public func track(c: Closure) { element("track", c) }
public func video(c: Closure) { element("video", c) }

public func applet(c: Closure) { element("applet", c) }
public func button(c: Closure) { element("button", c) }
public func canvas(c: Closure) { element("canvas", c) }
public func center(c: Closure) { element("center", c) }
public func dialog(c: Closure) { element("dialog", c) }
public func figure(c: Closure) { element("figure", c) }
public func footer(c: Closure) { element("footer", c) }
public func header(c: Closure) { element("header", c) }
public func hgroup(c: Closure) { element("hgroup", c) }
public func iframe(c: Closure) { element("iframe", c) }
public func keygen(c: Closure) { element("keygen", c) }
public func legend(c: Closure) { element("legend", c) }
public func object(c: Closure) { element("object", c) }
public func option(c: Closure) { element("option", c) }
public func output(c: Closure) { element("output", c) }
public func script(c: Closure) { element("script", c) }
public func select(c: Closure) { element("select", c) }
public func shadow(c: Closure) { element("shadow", c) }
public func source(c: Closure) { element("source", c) }
public func spacer(c: Closure) { element("spacer", c) }
public func strike(c: Closure) { element("strike", c) }
public func strong(c: Closure) { element("strong", c) }

public func acronym(c: Closure) { element("acronym", c) }
public func address(c: Closure) { element("address", c) }
public func article(c: Closure) { element("article", c) }
public func bgsound(c: Closure) { element("bgsound", c) }
public func caption(c: Closure) { element("caption", c) }
public func command(c: Closure) { element("command", c) }
public func content(c: Closure) { element("content", c) }
public func details(c: Closure) { element("details", c) }
public func elementt(c: Closure) { element("element", c) }
public func isindex(c: Closure) { element("isindex", c) }
public func listing(c: Closure) { element("listing", c) }
public func marquee(c: Closure) { element("marquee", c) }
public func noembed(c: Closure) { element("noembed", c) }
public func picture(c: Closure) { element("picture", c) }
public func section(c: Closure) { element("section", c) }
public func summary(c: Closure) { element("summary", c) }

public func basefont(c: Closure) { element("basefont", c) }
public func colgroup(c: Closure) { element("colgroup", c) }
public func datalist(c: Closure) { element("datalist", c) }
public func fieldset(c: Closure) { element("fieldset", c) }
public func frameset(c: Closure) { element("frameset", c) }
public func menuitem(c: Closure) { element("menuitem", c) }
public func multicol(c: Closure) { element("multicol", c) }
public func noframes(c: Closure) { element("noframes", c) }
public func noscript(c: Closure) { element("noscript", c) }
public func optgroup(c: Closure) { element("optgroup", c) }
public func progress(c: Closure) { element("progress", c) }
public func template(c: Closure) { element("template", c) }
public func textarea(c: Closure) { element("textarea", c) }

public func plaintext(c: Closure) { element("plaintext", c) }
public func javascript(c: Closure) { element("script", ["type": "text/javascript"], c) }
public func blockquote(c: Closure) { element("blockquote", c) }
public func figcaption(c: Closure) { element("figcaption", c) }

public func stylesheet(c: Closure) { element("link", ["rel": "stylesheet", "type": "text/css"], c) }

public func element(node: String, _ c: Closure) { evaluate(node, [:], c) }
public func element(node: String, _ attrs: [String: String?] = [:], _ c: Closure) { evaluate(node, attrs, c) }

var ScopesBuffer = [UInt64: String]()

private func evaluate(node: String, _ attrs: [String: String?] = [:], _ c: Closure) {
    
    // Push the attributes.
    
    let stackid = idd
    let stackdir = dir
    let stackrel = rel
    let stackrev = rev
    let stackalt = alt
    let stackfor = forr
    let stacksrc = src
    let stacktype = type
    let stackhref = href
    let stacktext = text
    let stackabbr = abbr
    let stacksize = size
    let stackface = face
    let stackchar = char
    let stackcite = cite
    let stackspan = span
    let stackdata = data
    let stackaxis = axis
    let stackName = Name
    let stackname = name
    let stackcode = code
    let stacklink = link
    let stacklang = lang
    let stackcols = cols
    let stackrows = rows
    let stackismap = ismap
    let stackshape = shape
    let stackstyle = style
    let stackalink = alink
    let stackwidth = width
    let stackrules = rules
    let stackalign = align
    let stackframe = frame
    let stackvlink = vlink
    let stackdefer = deferr
    let stackcolor = color
    let stackmedia = media
    let stacktitle = title
    let stackscope = scope
    let stackclass = classs
    let stackvalue = value
    let stackclear = clear
    let stackstart = start
    let stacklabel = label
    let stackaction = action
    let stackheight = height
    let stackmethod = method
    let stackaccept = acceptt
    let stackobject = object
    let stackscheme = scheme
    let stackcoords = coords
    let stackusemap = usemap
    let stackonblur = onblur
    let stacknohref = nohref
    let stacknowrap = nowrap
    let stackhspace = hspace
    let stackborder = border
    let stackvalign = valign
    let stackvspace = vspace
    let stackonload = onload
    let stacktarget = target
    let stackprompt = prompt
    let stackonfocus = onfocus
    let stackenctype = enctype
    let stackonclick = onclick
    let stackonkeyup = onkeyup
    let stackprofile = profile
    let stackversion = version
    let stackonreset = onreset
    let stackcharset = charset
    let stackstandby = standby
    let stackcolspan = colspan
    let stackcharoff = charoff
    let stackclassid = classid
    let stackcompact = compact
    let stackdeclare = declare
    let stackrowspan = rowspan
    let stackchecked = checked
    let stackarchive = archive
    let stackbgcolor = bgcolor
    let stackcontent = content
    let stacknoshade = noshade
    let stacksummary = summary
    let stackheaders = headers
    let stackonselect = onselect
    let stackreadonly = readonly
    let stacktabindex = tabindex
    let stackonchange = onchange
    let stacknoresize = noresize
    let stackdisabled = disabled
    let stacklongdesc = longdesc
    let stackcodebase = codebase
    let stacklanguage = language
    let stackdatetime = datetime
    let stackselected = selected
    let stackhreflang = hreflang
    let stackonsubmit = onsubmit
    let stackmultiple = multiple
    let stackonunload = onunload
    let stackcodetype = codetype
    let stackscrolling = scrolling
    let stackonkeydown = onkeydown
    let stackmaxlength = maxlength
    let stackvaluetype = valuetype
    let stackaccesskey = accesskey
    let stackonmouseup = onmouseup
    let stackonkeypress = onkeypress
    let stackondblclick = ondblclick
    let stackonmouseout = onmouseout
    let stackhttpEquiv = httpEquiv
    let stackbackground = background
    let stackonmousemove = onmousemove
    let stackonmouseover = onmouseover
    let stackcellpadding = cellpadding
    let stackonmousedown = onmousedown
    let stackframeborder = frameborder
    let stackmarginwidth = marginwidth
    let stackcellspacing = cellspacing
    let stackplaceholder = placeholder
    let stackmarginheight = marginheight
    let stackacceptCharset = acceptCharset
    let stackinner = inner
    
    // Reset the values before a nested scope evalutation.
    
    idd = nil
    dir = nil
    rel = nil
    rev = nil
    alt = nil
    forr = nil
    src = nil
    type = nil
    href = nil
    text = nil
    abbr = nil
    size = nil
    face = nil
    char = nil
    cite = nil
    span = nil
    data = nil
    axis = nil
    Name = nil
    name = nil
    code = nil
    link = nil
    lang = nil
    cols = nil
    rows = nil
    ismap = nil
    shape = nil
    style = nil
    alink = nil
    width = nil
    rules = nil
    align = nil
    frame = nil
    vlink = nil
    deferr = nil
    color = nil
    media = nil
    title = nil
    scope = nil
    classs = nil
    value = nil
    clear = nil
    start = nil
    label = nil
    action = nil
    height = nil
    method = nil
    acceptt = nil
    object = nil
    scheme = nil
    coords = nil
    usemap = nil
    onblur = nil
    nohref = nil
    nowrap = nil
    hspace = nil
    border = nil
    valign = nil
    vspace = nil
    onload = nil
    target = nil
    prompt = nil
    onfocus = nil
    enctype = nil
    onclick = nil
    onkeyup = nil
    profile = nil
    version = nil
    onreset = nil
    charset = nil
    standby = nil
    colspan = nil
    charoff = nil
    classid = nil
    compact = nil
    declare = nil
    rowspan = nil
    checked = nil
    archive = nil
    bgcolor = nil
    content = nil
    noshade = nil
    summary = nil
    headers = nil
    onselect = nil
    readonly = nil
    tabindex = nil
    onchange = nil
    noresize = nil
    disabled = nil
    longdesc = nil
    codebase = nil
    language = nil
    datetime = nil
    selected = nil
    hreflang = nil
    onsubmit = nil
    multiple = nil
    onunload = nil
    codetype = nil
    scrolling = nil
    onkeydown = nil
    maxlength = nil
    valuetype = nil
    accesskey = nil
    onmouseup = nil
    onkeypress = nil
    ondblclick = nil
    onmouseout = nil
    httpEquiv = nil
    background = nil
    onmousemove = nil
    onmouseover = nil
    cellpadding = nil
    onmousedown = nil
    frameborder = nil
    placeholder = nil
    marginwidth = nil
    cellspacing = nil
    marginheight = nil
    acceptCharset = nil
    inner = nil
    
    ScopesBuffer[Process.TID] = (ScopesBuffer[Process.TID] ?? "") + "<" + node
    
    // Save the current output before the nested scope evalutation.
    
    var output = ScopesBuffer[Process.TID] ?? ""
    
    // Clear the output buffer for the evalutation.
    
    ScopesBuffer[Process.TID] = ""
    
    // Evaluate the nested scope.
    
    c()
    
    // Render attributes set by the evalutation.
    
    var mergedAttributes = [String: String?]()
    
    if let idd = idd { mergedAttributes["id"] = idd }
    if let dir = dir { mergedAttributes["dir"] = dir }
    if let rel = rel { mergedAttributes["rel"] = rel }
    if let rev = rev { mergedAttributes["rev"] = rev }
    if let alt = alt { mergedAttributes["alt"] = alt }
    if let forr = forr { mergedAttributes["for"] = forr }
    if let src = src { mergedAttributes["src"] = src }
    if let type = type { mergedAttributes["type"] = type }
    if let href = href { mergedAttributes["href"] = href }
    if let text = text { mergedAttributes["text"] = text }
    if let abbr = abbr { mergedAttributes["abbr"] = abbr }
    if let size = size { mergedAttributes["size"] = size }
    if let face = face { mergedAttributes["face"] = face }
    if let char = char { mergedAttributes["char"] = char }
    if let cite = cite { mergedAttributes["cite"] = cite }
    if let span = span { mergedAttributes["span"] = span }
    if let data = data { mergedAttributes["data"] = data }
    if let axis = axis { mergedAttributes["axis"] = axis }
    if let Name = Name { mergedAttributes["Name"] = Name }
    if let name = name { mergedAttributes["name"] = name }
    if let code = code { mergedAttributes["code"] = code }
    if let link = link { mergedAttributes["link"] = link }
    if let lang = lang { mergedAttributes["lang"] = lang }
    if let cols = cols { mergedAttributes["cols"] = cols }
    if let rows = rows { mergedAttributes["rows"] = rows }
    if let ismap = ismap { mergedAttributes["ismap"] = ismap }
    if let shape = shape { mergedAttributes["shape"] = shape }
    if let style = style { mergedAttributes["style"] = style }
    if let alink = alink { mergedAttributes["alink"] = alink }
    if let width = width { mergedAttributes["width"] = width }
    if let rules = rules { mergedAttributes["rules"] = rules }
    if let align = align { mergedAttributes["align"] = align }
    if let frame = frame { mergedAttributes["frame"] = frame }
    if let vlink = vlink { mergedAttributes["vlink"] = vlink }
    if let deferr = deferr { mergedAttributes["defer"] = deferr }
    if let color = color { mergedAttributes["color"] = color }
    if let media = media { mergedAttributes["media"] = media }
    if let title = title { mergedAttributes["title"] = title }
    if let scope = scope { mergedAttributes["scope"] = scope }
    if let classs = classs { mergedAttributes["class"] = classs }
    if let value = value { mergedAttributes["value"] = value }
    if let clear = clear { mergedAttributes["clear"] = clear }
    if let start = start { mergedAttributes["start"] = start }
    if let label = label { mergedAttributes["label"] = label }
    if let action = action { mergedAttributes["action"] = action }
    if let height = height { mergedAttributes["height"] = height }
    if let method = method { mergedAttributes["method"] = method }
    if let acceptt = acceptt { mergedAttributes["accept"] = acceptt }
    if let object = object { mergedAttributes["object"] = object }
    if let scheme = scheme { mergedAttributes["scheme"] = scheme }
    if let coords = coords { mergedAttributes["coords"] = coords }
    if let usemap = usemap { mergedAttributes["usemap"] = usemap }
    if let onblur = onblur { mergedAttributes["onblur"] = onblur }
    if let nohref = nohref { mergedAttributes["nohref"] = nohref }
    if let nowrap = nowrap { mergedAttributes["nowrap"] = nowrap }
    if let hspace = hspace { mergedAttributes["hspace"] = hspace }
    if let border = border { mergedAttributes["border"] = border }
    if let valign = valign { mergedAttributes["valign"] = valign }
    if let vspace = vspace { mergedAttributes["vspace"] = vspace }
    if let onload = onload { mergedAttributes["onload"] = onload }
    if let target = target { mergedAttributes["target"] = target }
    if let prompt = prompt { mergedAttributes["prompt"] = prompt }
    if let onfocus = onfocus { mergedAttributes["onfocus"] = onfocus }
    if let enctype = enctype { mergedAttributes["enctype"] = enctype }
    if let onclick = onclick { mergedAttributes["onclick"] = onclick }
    if let onkeyup = onkeyup { mergedAttributes["onkeyup"] = onkeyup }
    if let profile = profile { mergedAttributes["profile"] = profile }
    if let version = version { mergedAttributes["version"] = version }
    if let onreset = onreset { mergedAttributes["onreset"] = onreset }
    if let charset = charset { mergedAttributes["charset"] = charset }
    if let standby = standby { mergedAttributes["standby"] = standby }
    if let colspan = colspan { mergedAttributes["colspan"] = colspan }
    if let charoff = charoff { mergedAttributes["charoff"] = charoff }
    if let classid = classid { mergedAttributes["classid"] = classid }
    if let compact = compact { mergedAttributes["compact"] = compact }
    if let declare = declare { mergedAttributes["declare"] = declare }
    if let rowspan = rowspan { mergedAttributes["rowspan"] = rowspan }
    if let checked = checked { mergedAttributes["checked"] = checked }
    if let archive = archive { mergedAttributes["archive"] = archive }
    if let bgcolor = bgcolor { mergedAttributes["bgcolor"] = bgcolor }
    if let content = content { mergedAttributes["content"] = content }
    if let noshade = noshade { mergedAttributes["noshade"] = noshade }
    if let summary = summary { mergedAttributes["summary"] = summary }
    if let headers = headers { mergedAttributes["headers"] = headers }
    if let onselect = onselect { mergedAttributes["onselect"] = onselect }
    if let readonly = readonly { mergedAttributes["readonly"] = readonly }
    if let tabindex = tabindex { mergedAttributes["tabindex"] = tabindex }
    if let onchange = onchange { mergedAttributes["onchange"] = onchange }
    if let noresize = noresize { mergedAttributes["noresize"] = noresize }
    if let disabled = disabled { mergedAttributes["disabled"] = disabled }
    if let longdesc = longdesc { mergedAttributes["longdesc"] = longdesc }
    if let codebase = codebase { mergedAttributes["codebase"] = codebase }
    if let language = language { mergedAttributes["language"] = language }
    if let datetime = datetime { mergedAttributes["datetime"] = datetime }
    if let selected = selected { mergedAttributes["selected"] = selected }
    if let hreflang = hreflang { mergedAttributes["hreflang"] = hreflang }
    if let onsubmit = onsubmit { mergedAttributes["onsubmit"] = onsubmit }
    if let multiple = multiple { mergedAttributes["multiple"] = multiple }
    if let onunload = onunload { mergedAttributes["onunload"] = onunload }
    if let codetype = codetype { mergedAttributes["codetype"] = codetype }
    if let scrolling = scrolling { mergedAttributes["scrolling"] = scrolling }
    if let onkeydown = onkeydown { mergedAttributes["onkeydown"] = onkeydown }
    if let maxlength = maxlength { mergedAttributes["maxlength"] = maxlength }
    if let valuetype = valuetype { mergedAttributes["valuetype"] = valuetype }
    if let accesskey = accesskey { mergedAttributes["accesskey"] = accesskey }
    if let onmouseup = onmouseup { mergedAttributes["onmouseup"] = onmouseup }
    if let onkeypress = onkeypress { mergedAttributes["onkeypress"] = onkeypress }
    if let ondblclick = ondblclick { mergedAttributes["ondblclick"] = ondblclick }
    if let onmouseout = onmouseout { mergedAttributes["onmouseout"] = onmouseout }
    if let httpEquiv = httpEquiv { mergedAttributes["http-equiv"] = httpEquiv }
    if let background = background { mergedAttributes["background"] = background }
    if let onmousemove = onmousemove { mergedAttributes["onmousemove"] = onmousemove }
    if let onmouseover = onmouseover { mergedAttributes["onmouseover"] = onmouseover }
    if let cellpadding = cellpadding { mergedAttributes["cellpadding"] = cellpadding }
    if let onmousedown = onmousedown { mergedAttributes["onmousedown"] = onmousedown }
    if let frameborder = frameborder { mergedAttributes["frameborder"] = frameborder }
    if let marginwidth = marginwidth { mergedAttributes["marginwidth"] = marginwidth }
    if let cellspacing = cellspacing { mergedAttributes["cellspacing"] = cellspacing }
    if let placeholder = placeholder { mergedAttributes["placeholder"] = placeholder }
    if let marginheight = marginheight { mergedAttributes["marginheight"] = marginheight }
    if let acceptCharset = acceptCharset { mergedAttributes["accept-charset"] = acceptCharset }
    
    for item in attrs.enumerate() {
        mergedAttributes.updateValue(item.element.1, forKey: item.element.0)
    }
    
    output = output + mergedAttributes.reduce("") {
        if let value = $0.1.1 {
            return $0.0 + " \($0.1.0)=\"\(value)\""
        } else {
            return $0.0
        }
    }
    
    if let inner = inner {
        ScopesBuffer[Process.TID] = output + ">" + (inner) + "</" + node + ">"
    } else {
        let current = ScopesBuffer[Process.TID]  ?? ""
        ScopesBuffer[Process.TID] = output + ">" + current + "</" + node + ">"
    }
    
    // Pop the attributes.
    
    idd = stackid
    dir = stackdir
    rel = stackrel
    rev = stackrev
    alt = stackalt
    forr = stackfor
    src = stacksrc
    type = stacktype
    href = stackhref
    text = stacktext
    abbr = stackabbr
    size = stacksize
    face = stackface
    char = stackchar
    cite = stackcite
    span = stackspan
    data = stackdata
    axis = stackaxis
    Name = stackName
    name = stackname
    code = stackcode
    link = stacklink
    lang = stacklang
    cols = stackcols
    rows = stackrows
    ismap = stackismap
    shape = stackshape
    style = stackstyle
    alink = stackalink
    width = stackwidth
    rules = stackrules
    align = stackalign
    frame = stackframe
    vlink = stackvlink
    deferr = stackdefer
    color = stackcolor
    media = stackmedia
    title = stacktitle
    scope = stackscope
    classs = stackclass
    value = stackvalue
    clear = stackclear
    start = stackstart
    label = stacklabel
    action = stackaction
    height = stackheight
    method = stackmethod
    acceptt = stackaccept
    object = stackobject
    scheme = stackscheme
    coords = stackcoords
    usemap = stackusemap
    onblur = stackonblur
    nohref = stacknohref
    nowrap = stacknowrap
    hspace = stackhspace
    border = stackborder
    valign = stackvalign
    vspace = stackvspace
    onload = stackonload
    target = stacktarget
    prompt = stackprompt
    onfocus = stackonfocus
    enctype = stackenctype
    onclick = stackonclick
    onkeyup = stackonkeyup
    profile = stackprofile
    version = stackversion
    onreset = stackonreset
    charset = stackcharset
    standby = stackstandby
    colspan = stackcolspan
    charoff = stackcharoff
    classid = stackclassid
    compact = stackcompact
    declare = stackdeclare
    rowspan = stackrowspan
    checked = stackchecked
    archive = stackarchive
    bgcolor = stackbgcolor
    content = stackcontent
    noshade = stacknoshade
    summary = stacksummary
    headers = stackheaders
    onselect = stackonselect
    readonly = stackreadonly
    tabindex = stacktabindex
    onchange = stackonchange
    noresize = stacknoresize
    disabled = stackdisabled
    longdesc = stacklongdesc
    codebase = stackcodebase
    language = stacklanguage
    datetime = stackdatetime
    selected = stackselected
    hreflang = stackhreflang
    onsubmit = stackonsubmit
    multiple = stackmultiple
    onunload = stackonunload
    codetype = stackcodetype
    scrolling = stackscrolling
    onkeydown = stackonkeydown
    maxlength = stackmaxlength
    valuetype = stackvaluetype
    accesskey = stackaccesskey
    onmouseup = stackonmouseup
    onkeypress = stackonkeypress
    ondblclick = stackondblclick
    onmouseout = stackonmouseout
    httpEquiv = stackhttpEquiv
    background = stackbackground
    onmousemove = stackonmousemove
    onmouseover = stackonmouseover
    cellpadding = stackcellpadding
    onmousedown = stackonmousedown
    frameborder = stackframeborder
    placeholder = stackplaceholder
    marginwidth = stackmarginwidth
    cellspacing = stackcellspacing
    marginheight = stackmarginheight
    acceptCharset = stackacceptCharset
    
    inner = stackinner
}
