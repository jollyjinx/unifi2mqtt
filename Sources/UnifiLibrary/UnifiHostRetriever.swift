//
//  Error.swift
//  unifi2mqtt
//
//  Created by Patrick Stein on 12.01.25.
//
import Foundation
import JLog
import AsyncHTTPClient
import NIOCore
import NIOFoundationCompat
import NIOHTTP1

struct UnifiHostRetriever
{
    internal let host: String
    internal let apiKey: String
    internal var siteId: String = ""
    internal let httpTimeout: TimeAmount
    internal let limit: Int

    public enum Error: Swift.Error
    {
        case invalidResponse
        case noDefaultSite
    }

    init(host: String, apiKey: String, siteId: String?, limit: Int = 100_000, httpTimeout: TimeAmount) async throws
    {
        self.host = host
        self.apiKey = apiKey

        self.limit = limit
        self.httpTimeout = httpTimeout

        if let siteId = siteId
        {
            self.siteId = siteId
        }
        else
        {
            self.siteId = try await defaultSiteId().id
        }
    }
}

extension UnifiHostRetriever
{
    func retrieve(path: String) async throws -> Data
    {
        var request = HTTPClientRequest(url: "https://\(host)\(path)")
        request.headers.add(name: "X-API-Key", value: apiKey)
        request.headers.add(name: "Accept", value: "application/json")

        let response = try await HTTPClientProvider.sharedHttpClient.execute(request, timeout: httpTimeout)
        guard response.status == .ok else { throw Error.invalidResponse }
        var bodyData = Data()
        for try await buffer in response.body
        {
            bodyData.append(Data(buffer: buffer))
        }
        JLog.trace("result: \(String(data: bodyData, encoding: .utf8) ?? "nil")")
        return bodyData
    }

    func retrieveAndParse<T: Decodable>(path: String, type: T.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) async throws -> T
    {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = dateDecodingStrategy

        let result:T = try jsonDecoder.decode(T.self, from: try await retrieve(path: path))
        return result
    }
}


extension UnifiHostRetriever
{
    func defaultSiteId() async throws -> UnifiSite
    {
        let path = "/proxy/network/integrations/v1/sites"
        let siteResponse = try await retrieveAndParse(path: path, type: UnifiSitesResponse.self)

        guard let site = siteResponse.data.first(where: { $0.name.lowercased() == "default" }) ?? siteResponse.data.first
        else
        {
            throw Error.noDefaultSite
        }
        return site
    }

    func oldDevices() async throws -> DeviceResponse
    {
        let path =  "/proxy/network/api/s/default/stat/device"
        return try await retrieveAndParse(path: path, type: DeviceResponse.self, dateDecodingStrategy:.secondsSince1970)
    }

    func clients(limit: Int = 0) async throws -> [UnifiClient]
    {
        let limit = limit > 0 ? limit : self.limit
        let path =  "/proxy/network/integrations/v1/sites/\(siteId)/clients?limit=\(limit)"
        return try await retrieveAndParse(path: path, type: UnifiClientsResponse.self).data
    }

    func devices() async throws -> [UnifiDevice]
    {
        let path =  "/proxy/network/integrations/v1/sites/\(siteId)/devices?limit=\(limit)"
        return try await retrieveAndParse(path: path, type: UnifiDevicesResponse.self).data
    }

    func deviceDetails(for device: UnifiDevice) async throws -> UnifiDeviceDetail
    {
        let path =  "/proxy/network/integrations/v1/sites/\(siteId)/devices/\(device.id)"
        let unifiDeviceDetail = try await retrieveAndParse(path: path, type: UnifiDeviceDetail.self)
        return unifiDeviceDetail
    }
}
