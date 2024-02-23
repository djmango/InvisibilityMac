//
//  CheckConnectivity.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/17/24.
//

import Foundation
import Network

func checkInternetConnectivity(completion: @escaping (Bool) -> Void) {
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { path in
        if path.status == .satisfied {
            completion(true)
        } else {
            completion(false)
        }
        monitor.cancel()
    }
    let queue = DispatchQueue(label: "Monitor")
    monitor.start(queue: queue)
}

func checkInternetConnectivityAsync() async -> Bool {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")

    return await withCheckedContinuation { continuation in
        monitor.pathUpdateHandler = { path in
            continuation.resume(returning: path.status == .satisfied)
            monitor.cancel()
        }
        monitor.start(queue: queue)
    }
}
