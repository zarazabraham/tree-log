//
//  MotionTokens.swift
//  Plantydex Design System
//
//  Animation duration and easing tokens for consistent motion.
//

import SwiftUI

/// Motion tokens for consistent animations and transitions.
struct MotionTokens {

    // MARK: - Duration Scale

    /// Instant - no animation (0ms)
    let instant: Double = 0

    /// Quick - very fast animations (150ms)
    let quick: Double = 0.15

    /// Fast - fast animations (250ms)
    let fast: Double = 0.25

    /// Normal - default animation speed (350ms)
    let normal: Double = 0.35

    /// Slow - slow animations (500ms)
    let slow: Double = 0.5

    /// Slower - very slow animations (700ms)
    let slower: Double = 0.7

    // MARK: - Easing Curves

    /// Linear easing - constant speed
    let linear = Animation.linear

    /// Ease in - slow start, fast end
    let easeIn = Animation.easeIn

    /// Ease out - fast start, slow end
    let easeOut = Animation.easeOut

    /// Ease in-out - slow start and end
    let easeInOut = Animation.easeInOut

    /// Spring - bouncy natural motion
    let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    /// Snappy spring - quick bouncy motion
    let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Smooth spring - gentle bouncy motion
    let springSmooth = Animation.spring(response: 0.45, dampingFraction: 0.75)
}

// MARK: - View Extensions for Motion

extension View {
    /// Apply animation with duration and easing tokens
    func animate(
        duration: MotionDuration,
        curve: MotionCurve = .easeInOut,
        value: some Equatable
    ) -> some View {
        self.animation(
            curve.animation.speed(1.0 / duration.value),
            value: value
        )
    }
}

/// Duration values for animations
enum MotionDuration {
    case instant
    case quick
    case fast
    case normal
    case slow
    case slower
    case custom(Double)

    var value: Double {
        let tokens = MotionTokens()
        switch self {
        case .instant: return tokens.instant
        case .quick: return tokens.quick
        case .fast: return tokens.fast
        case .normal: return tokens.normal
        case .slow: return tokens.slow
        case .slower: return tokens.slower
        case .custom(let value): return value
        }
    }
}

/// Easing curve values for animations
enum MotionCurve {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case spring
    case springSnappy
    case springSmooth

    var animation: Animation {
        let tokens = MotionTokens()
        switch self {
        case .linear: return tokens.linear
        case .easeIn: return tokens.easeIn
        case .easeOut: return tokens.easeOut
        case .easeInOut: return tokens.easeInOut
        case .spring: return tokens.spring
        case .springSnappy: return tokens.springSnappy
        case .springSmooth: return tokens.springSmooth
        }
    }
}
