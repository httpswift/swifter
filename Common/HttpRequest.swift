//
//  HttpRequest.swift
//  Swifter
//
//  Created by Damian Kolakowski on 19/08/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

struct HttpRequest {
    let url: String
    let method: String
    let headers: Dictionary<String, String>
}
