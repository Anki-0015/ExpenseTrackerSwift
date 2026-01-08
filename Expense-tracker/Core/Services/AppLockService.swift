import Foundation
import LocalAuthentication

struct AppLockService {
    enum UnlockResult: Equatable {
        case unlocked
        case failed(String)
        case unavailable
    }

    func unlock(reason: String) async -> UnlockResult {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .unavailable
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalError in
                if success {
                    continuation.resume(returning: .unlocked)
                } else {
                    let message = (evalError as NSError?)?.localizedDescription ?? "Authentication failed"
                    continuation.resume(returning: .failed(message))
                }
            }
        }
    }
}
