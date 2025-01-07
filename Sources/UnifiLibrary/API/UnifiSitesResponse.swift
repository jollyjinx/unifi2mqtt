//
//  UnifiSitesResponse.swift
//

import Foundation

public struct UnifiSitesResponse: Codable, Sendable, Hashable, Equatable
{
    let offset: Int
    let limit: Int
    let count: Int
    let totalCount: Int
    let data: [UnifiSite]
}
