//
//  String+PathSegment.swift
//  InnerLamp
//

import Foundation

nonisolated extension String {
    /// Percent-encodes the string for use as a single URL path segment — `/`, `?` and `#` are
    /// escaped so an id can never change the route it is interpolated into.
    var pathSegmentEncoded: String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
