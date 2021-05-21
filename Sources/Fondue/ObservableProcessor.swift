//
//  ViewModelProvider.swift
//  Fondue
//
//  Created by Vikram Kriplaney on 30.11.19.
//

import Foundation

#if canImport(Combine)
import Combine

@available(iOS 13.0, tvOS 13.0, OSX 10.15, macCatalyst 13.0, watchOS 6.0, *)
/// A generic view model implementation
///
///     struct SomeView: View {
///         @StateObject var model = ObservableProcessor { SomeAPI.get() }
///         :
///     }
public class ObservableProcessor<Input, Output>: ObservableObject {
    @Published public var input: Input?
    @Published public var output: Output?
    @Published public var isBusy = false
    @Published public var hasError = false
    @Published public var error: Error? {
        didSet { hasError = error != nil }
    }

    public typealias Processor = (Input) -> AnyPublisher<Output, Error>
    let uiQueue = DispatchQueue.main
    var holder, cancellable: AnyCancellable?

    var delay: DispatchQueue.SchedulerTimeType.Stride = 0
    var debounce: DispatchQueue.SchedulerTimeType.Stride = 0.25
    var timeout: DispatchQueue.SchedulerTimeType.Stride = 10
    var retries: Int = 3
    var queue: DispatchQueue = .global(qos: .userInitiated)

    public init(processor: @escaping Processor) {
        self.holder = $input
            .delay(for: delay, scheduler: uiQueue)
            .debounce(for: debounce, scheduler: uiQueue)
            .sink { input in
                guard let input = input else { return }
                self.cancellable?.cancel()
                self.isBusy = true
                self.cancellable = processor(input)
                    .timeout(self.timeout, scheduler: self.uiQueue)
                    .retry(self.retries)
                    .receive(on: self.uiQueue)
                    .sink(receiveCompletion: { completion in
                        self.isBusy = false
                        if case let .failure(error) = completion {
                            self.error = error
                            debugPrint(error)
                        } else {
                            self.error = nil
                        }
                    }, receiveValue: { value in
                        self.output = value
                    })
            }
    }

    // Triggers an update without inputs
    @discardableResult public func start() -> Self {
        input = () as? Input
        return self
    }

    // Triggers an update without inputs if not already started
    @discardableResult public func autostart() -> Self {
        if output == nil {
            start()
        }
        return self
    }

    @discardableResult public func delay(_ value: DispatchQueue.SchedulerTimeType.Stride) -> Self {
        delay = value
        return self
    }

    @discardableResult public func debounce(_ value: DispatchQueue.SchedulerTimeType.Stride) -> Self {
        debounce = value
        return self
    }

    @discardableResult public func timeout(_ value: DispatchQueue.SchedulerTimeType.Stride) -> Self {
        timeout = value
        return self
    }

    @discardableResult public func retry(_ value: Int) -> Self {
        retries = value
        return self
    }

    @discardableResult public func queue(_ value: DispatchQueue) -> Self {
        queue = value
        return self
    }
}
import SwiftUI
#endif
