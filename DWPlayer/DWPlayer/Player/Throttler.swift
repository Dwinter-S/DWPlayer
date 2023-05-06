//
//  Throttler.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/24.
//

import Foundation

class Throttler {
    private let queue: DispatchQueue
    private let interval: TimeInterval
    private let semaphore: DebouncerSemaphore
    private var workItem: DispatchWorkItem?
    private var lastExecuteTime = Date()
    
    init(seconds: TimeInterval, qos: DispatchQoS = .default) {
        interval = seconds
        semaphore = DebouncerSemaphore(value: 1)
        queue = DispatchQueue(label: "throttler.queue", qos: qos)
    }
    
    func invoke(onQueue: DispatchQueue = DispatchQueue.main, _ action: @escaping (() -> Void)) {
        semaphore.sync {
            workItem?.cancel()
            workItem = DispatchWorkItem(block: { [weak self] in
                self?.lastExecuteTime = Date()
                onQueue.async {
                    action()
                }
            })
            let deadline = Date().timeIntervalSince(lastExecuteTime) > interval ? 0 : interval
            if let item = workItem {
                queue.asyncAfter(deadline: .now() + deadline, execute: item)
            }
        }
    }
}

class Debouncer {
    private let queue: DispatchQueue
    private let interval: TimeInterval
    private let semaphore: DebouncerSemaphore
    private var workItem: DispatchWorkItem?

    init(seconds: TimeInterval, qos: DispatchQoS = .default) {
        interval = seconds
        semaphore = DebouncerSemaphore(value: 1)
        queue = DispatchQueue(label: "debouncer.queue", qos: qos)
    }
    
    func invoke(_ action: @escaping (() -> Void)) {
        semaphore.sync {
            workItem?.cancel()
            workItem = DispatchWorkItem(block: {
                action()
            })
            if let item = workItem {
                queue.asyncAfter(deadline: .now() + self.interval, execute: item)
            }
        }
    }
}

struct DebouncerSemaphore {
    private let semaphore: DispatchSemaphore
    
    init(value: Int) {
        semaphore = DispatchSemaphore(value: value)
    }
    
    func sync(execute: () -> Void) {
        defer { semaphore.signal() }
        semaphore.wait()
        execute()
    }
}


