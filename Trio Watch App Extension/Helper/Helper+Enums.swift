import SwiftUI
import WatchKit

enum NavigationDestinations: String {
    case acknowledgmentPending = "AcknowledgmentPendingView"
    case carbsInput = "CarbsInputView"
    case bolusInput = "BolusInputView"
    case bolusConfirm = "BolusConfirmView"
}

enum MealBolusStep: String {
    case savingCarbs = "Saving Carbs..."
    case enactingBolus = "Enacting Bolus..."
}

enum AcknowledgementStatus: String, CaseIterable {
    case success
    case failure
    case pending
}

enum AcknowledgmentCode: String, Codable {
    case savingCarbs = "saving_carbs"
    case enactingBolus = "enacting_bolus"
    case comboComplete = "combo_complete"
    case carbsLogged = "carbs_logged"
    case overrideStarted = "override_started"
    case overrideStopped = "override_stopped"
    case tempTargetStarted = "temp_target_started"
    case tempTargetStopped = "temp_target_stopped"
    case genericSuccess = "success"
    case genericFailure = "failure"
}

enum WatchSize {
    case watch40mm
    case watch41mm
    case watch42mm
    case watch44mm
    case watch45mm
    case watch49mm
    case unknown

    static var current: WatchSize {
        let bounds = WKInterfaceDevice.current().screenBounds

        switch bounds {
        case CGRect(x: 0, y: 0, width: 162, height: 197):
            return .watch40mm // check

        case CGRect(x: 0, y: 0, width: 176, height: 215):
            return .watch41mm // check

        case CGRect(x: 0, y: 0, width: 187, height: 223):
            return .watch42mm // check

        case CGRect(x: 0, y: 0, width: 184, height: 224):
            return .watch44mm

        case CGRect(x: 0, y: 0, width: 198, height: 242):
            return .watch45mm

        case CGRect(x: 0, y: 0, width: 205, height: 251):
            return .watch49mm
        default:
            return .unknown
        }
    }
}

// MARK: - Trend Conversion

/// Map trend value string representations of trend to unicode arrows
enum TrendDirection: String, CaseIterable {
    case tripleUp = "TripleUp"
    case doubleUp = "DoubleUp"
    case singleUp = "SingleUp"
    case fortyFiveUp = "FortyFiveUp"
    case flat = "Flat"
    case fortyFiveDown = "FortyFiveDown"
    case singleDown = "SingleDown"
    case doubleDown = "DoubleDown"
    case tripleDown = "TripleDown"
    case none = "NONE"
    case notComputable = "NOT COMPUTABLE"
    case rateOutOfRange = "RATE OUT OF RANGE"

    /// Maps direction to its visual arrow representation
    var symbol: String {
        switch self {
        case .tripleUp: return "↑↑↑"
        case .doubleUp: return "↑↑"
        case .singleUp: return "↑"
        case .fortyFiveUp: return "↗"
        case .flat: return "→"
        case .fortyFiveDown: return "↘"
        case .singleDown: return "↓"
        case .doubleDown: return "↓↓"
        case .tripleDown: return "↓↓↓"
        case .none,
             .notComputable,
             .rateOutOfRange: return ""
        }
    }

    /// Flexible initializer that handles raw values (e.g. "FortyFiveUp") as well as arrow symbols (e.g. "↗")
    init?(from string: String) {
        guard !string.isEmpty else { return nil }
        if let directMatch = TrendDirection(rawValue: string) {
            self = directMatch
        } else if let symbolMatch = TrendDirection.allCases.first(where: { !$0.symbol.isEmpty && $0.symbol == string }) {
            self = symbolMatch
        } else {
            return nil
        }
    }
}
