//
//  StabilityUtils.swift
//  Chit Chat Social
//
//  Crash prevention and stability helpers.
//

import Foundation
import SwiftUI

// MARK: - Safe Array Access
extension Array {
    /// Safe subscript; returns nil if index is out of bounds.
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

    /// Safe first element.
    var safeFirst: Element? { first }

    /// Clamp index to valid range.
    func clampedIndex(_ index: Int) -> Int {
        guard !isEmpty else { return 0 }
        return Swift.max(0, Swift.min(index, count - 1))
    }
}

// MARK: - Main-Actor Guarantee
/// Runs work on main actor after a short delay to avoid state update conflicts.
func runOnMain(after delay: TimeInterval = 0.05, _ work: @escaping @Sendable () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        work()
    }
}

// MARK: - Debounce for rapid taps
final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?

    init(delay: TimeInterval = 0.35) {
        self.delay = delay
    }

    func debounce(_ block: @escaping () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: block)
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak item] in
            item?.perform()
        }
    }
}

// MARK: - Throttle for scroll/gesture-heavy updates
final class Throttler {
    private var lastRun: Date = .distantPast
    private let interval: TimeInterval
    private let queue = DispatchQueue(label: "com.chitchat.throttle")

    init(interval: TimeInterval = 0.15) {
        self.interval = interval
    }

    func throttle(_ block: @escaping () -> Void) {
        queue.async { [weak self] in
            guard let self else { return }
            let now = Date()
            guard now.timeIntervalSince(lastRun) >= interval else { return }
            lastRun = now
            DispatchQueue.main.async { block() }
        }
    }
}
