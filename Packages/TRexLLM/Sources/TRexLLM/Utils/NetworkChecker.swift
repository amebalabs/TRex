import Foundation
import Network
import os

/// Checks network connectivity
public final class NetworkChecker: Sendable {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.trex.llm.network")
    private let _isConnected: OSAllocatedUnfairLock<Bool>

    public init() {
        _isConnected = OSAllocatedUnfairLock(initialState: false)
        monitor = NWPathMonitor()
        let isConnected = _isConnected
        monitor.pathUpdateHandler = { path in
            isConnected.withLock { $0 = path.status == .satisfied }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    /// Check if network is available
    /// - Returns: True if network is available
    public func isNetworkAvailable() -> Bool {
        return _isConnected.withLock { $0 }
    }

    /// Check connectivity to a specific host
    /// - Parameter url: URL to check
    /// - Returns: True if host is reachable
    public func checkConnectivity(to url: URL) async -> Bool {
        // Quick check if network is available at all
        guard _isConnected.withLock({ $0 }) else {
            return false
        }

        // Try a HEAD request to the host
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 404
            }
            return false
        } catch {
            return false
        }
    }
}
