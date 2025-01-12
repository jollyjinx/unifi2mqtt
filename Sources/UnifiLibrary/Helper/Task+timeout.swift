//
//  Task+timeout.swift
//

import Foundation

#if os(Linux)
public let NSEC_PER_SEC: UInt64 = 1_000_000_000
#endif

public struct TimeoutError: LocalizedError
{
    public var errorDescription: String?

    init(_ description: String)
    {
        errorDescription = description
    }
}

#if compiler(>=6.0)
    public func withThrowingTimeout<T>(isolation: isolated (any Actor)? = #isolation,
                                       seconds: TimeInterval,
                                       body: () async throws -> sending T) async throws -> sending T
    {
        try await _withThrowingTimeout(isolation: isolation, body: body)
        {
            try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
            throw TimeoutError("Task timed out before completion. Timeout: \(seconds) seconds.")
        }.value
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func withThrowingTimeout<T, C: Clock>(isolation: isolated (any Actor)? = #isolation,
                                                 after instant: C.Instant,
                                                 tolerance: C.Instant.Duration? = nil,
                                                 clock: C,
                                                 body: () async throws -> sending T) async throws -> sending T
    {
        try await _withThrowingTimeout(isolation: isolation, body: body)
        {
            try await Task.sleep(until: instant, tolerance: tolerance, clock: clock)
            throw TimeoutError("Task timed out before completion. Deadline: \(instant).")
        }.value
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func withThrowingTimeout<T>(isolation: isolated (any Actor)? = #isolation,
                                       after instant: ContinuousClock.Instant,
                                       tolerance: ContinuousClock.Instant.Duration? = nil,
                                       body: () async throws -> sending T) async throws -> sending T
    {
        try await _withThrowingTimeout(isolation: isolation, body: body)
        {
            try await Task.sleep(until: instant, tolerance: tolerance, clock: ContinuousClock())
            throw TimeoutError("Task timed out before completion. Deadline: \(instant).")
        }.value
    }

    private func _withThrowingTimeout<T>(isolation: isolated (any Actor)? = #isolation,
                                         body: () async throws -> sending T,
                                         timeout: @Sendable @escaping () async throws -> Never) async throws -> Transferring<T>
    {
        try await withoutActuallyEscaping(body)
        { escapingBody in
            let bodyTask = Task
            {
                defer { _ = isolation }
                return try await Transferring(escapingBody())
            }
            let timeoutTask = Task
            {
                defer { bodyTask.cancel() }
                try await timeout()
            }

            let bodyResult = await withTaskCancellationHandler
            {
                await bodyTask.result
            } onCancel: {
                bodyTask.cancel()
            }
            timeoutTask.cancel()

            if case let .failure(timeoutError) = await timeoutTask.result,
               timeoutError is TimeoutError
            {
                throw timeoutError
            }
            else
            {
                return try bodyResult.get()
            }
        }
    }

    private struct Transferring<Value>: Sendable
    {
        public nonisolated(unsafe) var value: Value
        init(_ value: Value)
        {
            self.value = value
        }
    }
#else
    public func withThrowingTimeout<T>(seconds: TimeInterval,
                                       body: () async throws -> T) async throws -> T
    {
        let transferringBody = { try await Transferring(body()) }
        return try await withoutActuallyEscaping(transferringBody)
        {
            try await _withThrowingTimeout(body: $0)
            {
                try await Task.sleep(nanoseconds: UInt64(seconds * NSEC_PER_SEC))
                throw TimeoutError("Task timed out before completion. Timeout: \(seconds) seconds.")
            }
        }.value
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func withThrowingTimeout<T>(after instant: ContinuousClock.Instant,
                                       tolerance: ContinuousClock.Instant.Duration? = nil,
                                       body: () async throws -> T) async throws -> T
    {
        try await withThrowingTimeout(after: instant,
                                      tolerance: tolerance,
                                      clock: ContinuousClock(),
                                      body: body)
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func withThrowingTimeout<T, C: Clock>(after instant: C.Instant,
                                                 tolerance: C.Instant.Duration? = nil,
                                                 clock: C,
                                                 body: () async throws -> T) async throws -> T
    {
        let transferringBody = { try await Transferring(body()) }
        return try await withoutActuallyEscaping(transferringBody)
        {
            try await _withThrowingTimeout(body: $0)
            {
                try await Task.sleep(until: instant, tolerance: tolerance, clock: clock)
                throw TimeoutError("Task timed out before completion. Deadline: \(instant).")
            }
        }.value
    }

    // Sendable
    private func _withThrowingTimeout<T: Sendable>(body: @escaping () async throws -> T,
                                                   timeout: @Sendable @escaping () async throws -> Never) async throws -> T
    {
        let body = Transferring(body)
        return try await withThrowingTaskGroup(of: T.self)
        { group in
            group.addTask
            {
                try await body.value()
            }
            group.addTask
            {
                try await timeout()
            }
            let success = try await group.next()!
            group.cancelAll()
            return success
        }
    }

    private struct Transferring<Value>: @unchecked Sendable
    {
        var value: Value
        init(_ value: Value)
        {
            self.value = value
        }
    }
#endif
