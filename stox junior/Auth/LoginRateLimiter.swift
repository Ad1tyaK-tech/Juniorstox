import Foundation

struct LoginRateLimiter {

    // Tier 0 → 5 failures → soft lock (5 min)  → show create/forgot
    // Tier 1 → 5 failures → day lock  (24 hr)
    // Tier 2 → 2 failures → indefinite
    // Tier 3 → permanently blocked
    enum LockState: Equatable {
        case allowed
        case softLocked(until: Date)
        case dayLocked(until: Date)
        case indefinite
    }

    private let tierKey      = "login.tier"
    private let attemptsKey  = "login.attempts"
    private let lockUntilKey = "login.lockUntil"

    func lockState() -> LockState {
        let tier = UserDefaults.standard.integer(forKey: tierKey)
        if tier == 3 { return .indefinite }

        let t = UserDefaults.standard.double(forKey: lockUntilKey)
        guard t > 0 else { return .allowed }
        let lockDate = Date(timeIntervalSince1970: t)
        guard lockDate > .now else { return .allowed }

        switch tier {
        case 1: return .softLocked(until: lockDate)
        case 2: return .dayLocked(until: lockDate)
        default: return .allowed
        }
    }

    func recordFailure() {
        let tier = UserDefaults.standard.integer(forKey: tierKey)
        guard tier < 3 else { return }

        // Don't count while actively locked
        let t = UserDefaults.standard.double(forKey: lockUntilKey)
        if t > 0, Date(timeIntervalSince1970: t) > .now { return }

        let attempts = UserDefaults.standard.integer(forKey: attemptsKey) + 1
        UserDefaults.standard.set(attempts, forKey: attemptsKey)

        switch tier {
        case 0 where attempts >= 5: applyLock(tier: 1, duration: 5 * 60)
        case 1 where attempts >= 5: applyLock(tier: 2, duration: 24 * 3600)
        case 2 where attempts >= 2: applyLock(tier: 3, duration: nil)
        default: break
        }
    }

    func recordSuccess() {
        UserDefaults.standard.removeObject(forKey: tierKey)
        UserDefaults.standard.removeObject(forKey: attemptsKey)
        UserDefaults.standard.removeObject(forKey: lockUntilKey)
    }

    private func applyLock(tier: Int, duration: TimeInterval?) {
        UserDefaults.standard.set(tier, forKey: tierKey)
        UserDefaults.standard.set(0, forKey: attemptsKey)
        if let duration {
            UserDefaults.standard.set(
                Date.now.addingTimeInterval(duration).timeIntervalSince1970,
                forKey: lockUntilKey
            )
        }
    }
}
