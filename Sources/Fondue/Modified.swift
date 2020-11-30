//
//  Modified.swift
//  Fondue
//
//  Created by Vikram Kriplaney on 30.11.19.
//

/// A convenience top-level function used to "modify" immutable values in a closure,
/// returning a new, modified instance.
/// - Parameters:
///   - value: The value type to be "modified"
///   - closure: A closure to which a mutable copy is passed
/// - Throws: Just rethrows any possible errors
/// - Returns: A modifed value
///
/// Example:
///
///     static let formatter = modified(DateFormatter()) {
///         $0.dateStyle = .short
///         $0.timeStyle = .none
///     }

public func modified<T>(
    _ value: T,
    with closure: (inout T) throws -> Void
) rethrows -> T {
    var copy = value
    try closure(&copy)
    return copy
}
