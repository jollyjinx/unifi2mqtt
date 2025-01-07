//
//  UnifiHost.swift
//

import Foundation
import JLog

import AsyncHTTPClient
import NIOCore
import NIOFoundationCompat
import NIOHTTP1

@Observable
@MainActor
public final class UnifiHost
{
    private let host: String
    private let apiKey: String
    private let siteId: String
    private let refreshInterval: TimeInterval

    private let request: HTTPClientRequest
    private let httpTimeout: TimeAmount

    static func findOutDefaultSiteId(host: String, apiKey: String, timeout: TimeAmount = .seconds(5)) async throws -> String
    {
        JLog.debug("Finding default site id")

        var request = HTTPClientRequest(url: "https://\(host)/proxy/network/integrations/v1/sites")
        request.headers.add(name: "X-API-Key", value: apiKey)
        request.headers.add(name: "Accept", value: "application/json")

        let response = try await HTTPClientProvider.sharedHttpClient.execute(request, timeout: timeout)

        guard response.status == .ok else { throw Error.invalidResponse }

        var bodyData = Data()

        for try await buffer in response.body
        {
            bodyData.append(Data(buffer: buffer))
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        let siteResponse = try jsonDecoder.decode(UnifiSitesResponse.self, from: bodyData)

        guard let site = siteResponse.data.first(where: { $0.name.lowercased() == "default" }) ?? siteResponse.data.first
        else
        {
            throw Error.invalidResponse
        }
        JLog.debug("Default site id found: \(site.id)")
        return site.id
    }

    public init(host: String, apiKey: String, siteId: String?, refreshInterval: TimeInterval = 60.0, limit: Int = 100_000, timeout: TimeAmount = .seconds(5)) async throws
    {
        if let siteId, !siteId.isEmpty
        {
            self.siteId = siteId
        }
        else
        {
            self.siteId = try await UnifiHost.findOutDefaultSiteId(host: host, apiKey: apiKey, timeout: timeout)
        }

        self.host = host
        self.apiKey = apiKey

        self.refreshInterval = refreshInterval
        httpTimeout = timeout
        var request = HTTPClientRequest(url: "https://\(host)/proxy/network/integrations/v1/sites/\(self.siteId)/clients?limit=\(limit)")
        request.headers.add(name: "X-API-Key", value: apiKey)
        request.headers.add(name: "Accept", value: "application/json")
        self.request = request
    }

    public func run() async
    {
        while !Task.isCancelled
        {
            do
            {
                try await update()
            }
            catch
            {
                JLog.error("Error: \(error)")
            }
            try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
        }
    }

    public var clients: Set<UnifiClient> = []
}

extension UnifiHost
{
    public enum Error: Swift.Error
    {
        case invalidURL
        case invalidResponse
    }

    func update() async throws
    {
        let response = try await HTTPClientProvider.sharedHttpClient.execute(request, timeout: httpTimeout)
        guard response.status == .ok else { throw Error.invalidResponse }
        var bodyData = Data()
        for try await buffer in response.body
        {
            bodyData.append(Data(buffer: buffer))
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        let unifiClients = try jsonDecoder.decode(UnifiClientsResponse.self, from: bodyData)

        let newClientSet = Set(unifiClients.data)
        if newClientSet != clients
        {
            clients = newClientSet
        }
    }
}
