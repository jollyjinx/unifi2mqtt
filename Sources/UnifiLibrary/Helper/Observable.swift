//
//  Observable.swift
//

struct Observable<T: Sendable> {
    private var continuation: AsyncStream<T>.Continuation!
    private let stream: AsyncStream<T>

    init() {
        var localContinuation: AsyncStream<T>.Continuation!
        self.stream = AsyncStream { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation
    }

    func observe() -> AsyncStream<T> {
        return stream
    }

    func emit(_ value: T) {
        continuation?.yield(value)
    }
}
