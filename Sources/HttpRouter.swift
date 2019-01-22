//
//  HttpRouter.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation


open class HttpRouter {
    
    public init() {
    }
    
    private class Node {
        var nodes = [String: Node]()
        var handler: ((HttpRequest) -> HttpResponse)? = nil
    }
    
    private var rootNode = Node()

    public func routes() -> [String] {
        var routes = [String]()
        for (_, child) in rootNode.nodes {
            routes.append(contentsOf: routesForNode(child));
        }
        return routes
    }
    
    private func routesForNode(_ node: Node, prefix: String = "") -> [String] {
        var result = [String]()
        if let _ = node.handler {
            result.append(prefix)
        }
        for (key, child) in node.nodes {
            result.append(contentsOf: routesForNode(child, prefix: prefix + "/" + key));
        }
        return result
    }
    
    public func register(_ method: String?, path: String, handler: ((HttpRequest) -> HttpResponse)?) {
        var pathSegments = stripQuery(path).split("/")
        if let method = method {
            pathSegments.insert(method, at: 0)
        } else {
            pathSegments.insert("*", at: 0)
        }
        var pathSegmentsGenerator = pathSegments.makeIterator()
        inflate(&rootNode, generator: &pathSegmentsGenerator).handler = handler
    }
    
    public func route(_ method: String?, path: String) -> ([String: String], (HttpRequest) -> HttpResponse)? {
        if let method = method {
            let pathSegments = (method + "/" + stripQuery(path)).split("/")
            var pathSegmentsGenerator = pathSegments.makeIterator()
            var params = [String:String]()
            if let handler = findHandler(&rootNode, params: &params, generator: &pathSegmentsGenerator) {
                return (params, handler)
            }
        }
        let pathSegments = ("*/" + stripQuery(path)).split("/")
        var pathSegmentsGenerator = pathSegments.makeIterator()
        var params = [String:String]()
        if let handler = findHandler(&rootNode, params: &params, generator: &pathSegmentsGenerator) {
            return (params, handler)
        }
        return nil
    }
    
    private func inflate(_ node: inout Node, generator: inout IndexingIterator<[String]>) -> Node {
        if let pathSegment = generator.next() {
            if let _ = node.nodes[pathSegment] {
                return inflate(&node.nodes[pathSegment]!, generator: &generator)
            }
            var nextNode = Node()
            node.nodes[pathSegment] = nextNode
            return inflate(&nextNode, generator: &generator)
        }
        return node
    }
    
    private func findHandler(_ node: inout Node, params: inout [String: String], generator: inout IndexingIterator<[String]>) -> ((HttpRequest) -> HttpResponse)? {
        
        var matchedRoutes = [Node]()
        findHandler(&node, params: &params, generator: &generator, matchedNodes: &matchedRoutes, index: 0, count: generator.reversed().count)
        return matchedRoutes.first?.handler
    }
    
    /// Find the handlers for a specified route
    ///
    /// - Parameters:
    ///   - node: The root node of the tree representing all the routes
    ///   - params: The parameters of the match
    ///   - generator: The IndexingIterator to iterate through the pattern to match
    ///   - matchedNodes: An array with the nodes matching the route
    ///   - index: The index of current position in the generator
    ///   - count: The number of elements if the route to match
    private func findHandler(_ node: inout Node, params: inout [String: String], generator: inout IndexingIterator<[String]>, matchedNodes: inout [Node], index: Int, count: Int) {
    
        if let pathToken = generator.next()?.removingPercentEncoding {
            
            var currentIndex = index + 1
            let variableNodes = node.nodes.filter { $0.0.first == ":" }
            if let variableNode = variableNodes.first {
                if variableNode.1.nodes.count == 0 {
                    // if it's the last element of the pattern and it's a variable, stop the search and
                    // append a tail as a value for the variable.
                    let tail = generator.joined(separator: "/")
                    if tail.count > 0 {
                        params[variableNode.0] = pathToken + "/" + tail
                    } else {
                        params[variableNode.0] = pathToken
                    }
                    
                    matchedNodes.append(variableNode.value)
                    return
                }
                params[variableNode.0] = pathToken
                findHandler(&node.nodes[variableNode.0]!, params: &params, generator: &generator, matchedNodes: &matchedNodes, index: currentIndex, count: count)
            }
            
            if var node = node.nodes[pathToken] {
                findHandler(&node, params: &params, generator: &generator, matchedNodes: &matchedNodes, index: currentIndex, count: count)
            }
            
            if var node = node.nodes["*"] {
                findHandler(&node, params: &params, generator: &generator, matchedNodes: &matchedNodes, index: currentIndex, count: count)
            }
            
            if let startStarNode = node.nodes["**"] {
                let startStarNodeKeys = startStarNode.nodes.keys
                while let pathToken = generator.next() {
                    currentIndex += 1
                    if startStarNodeKeys.contains(pathToken) {
                        findHandler(&startStarNode.nodes[pathToken]!, params: &params, generator: &generator, matchedNodes: &matchedNodes, index: currentIndex, count: count)
                    }
                }
            }
        } else if let variableNode = node.nodes.filter({ $0.0.first == ":" }).first {
            // if it's the last element of the requested URL, check if there is a pattern with variable tail.
            if variableNode.value.nodes.isEmpty {
                params[variableNode.0] = ""
                matchedNodes.append(variableNode.value)
                return
            }
        }
        
        // if it's the last element and the path to match is done then it's a pattern matching
        if node.nodes.isEmpty && index == count {
            matchedNodes.append(node)
            return
        }
    }
    
    private func stripQuery(_ path: String) -> String {
        if let path = path.components(separatedBy: "?").first {
            return path
        }
        return path
    }
}

extension String {
    
    func split(_ separator: Character) -> [String] {
        return self.split { $0 == separator }.map(String.init)
    }
    
}
