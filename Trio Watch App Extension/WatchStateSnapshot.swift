//
//  WatchStateSnapshot.swift
//  Trio
//
//  Created by Cengiz Deniz on 18.04.25.
//
import Foundation

enum WatchStateSnapshot {
    private static let storageKey = "WatchStateSnapshot.latest"

    static func saveLatestDateToDisk(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: storageKey)
    }

    static func loadLatestDateFromDisk() -> Date {
        let interval = UserDefaults.standard.double(forKey: storageKey)
        return Date(timeIntervalSince1970: interval)
    }
}

// MARK: - Complication Data Model

struct ComplicationGlucose: Codable, Equatable, Sendable {
    /// Maximum age in seconds before complication data is considered stale (15 minutes).
    static let staleThreshold: TimeInterval = 15 * 60

    let currentGlucose: String
    let currentGlucoseColorString: String
    let trend: String
    let date: Date

    var isStale: Bool {
        date == Date.distantPast || Date().timeIntervalSince(date) > Self.staleThreshold
    }

    var staleDate: Date {
        date.addingTimeInterval(Self.staleThreshold)
    }

    var direction: TrendDirection? {
        !isStale ? TrendDirection(from: trend) : nil
    }

    var trendArrow: String {
        direction?.symbol ?? ""
    }

    static let placeholder = ComplicationGlucose(
        currentGlucose: "120",
        currentGlucoseColorString: "#00ff00",
        trend: "Flat",
        date: Date()
    )

    static let empty = ComplicationGlucose(
        currentGlucose: "--",
        currentGlucoseColorString: "#ffffff",
        trend: "",
        date: .distantPast
    )
}

// MARK: - Complication Storage

enum WatchComplicationData {
    static let appGroupId: String = {
        if let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String, !id.isEmpty {
            return id
        }
        if let bundleId = Bundle.main.bundleIdentifier {
            let parts = bundleId.split(separator: ".")
            if parts.count >= 3, parts[0] == "org", parts[1] == "nightscout" {
                let teamId = parts[2]
                return "group.org.nightscout.\(teamId).trio.trio-app-group"
            }
        }
        return "group.org.nightscout.trio.trio-app-group"
    }()

    private static let glucoseKey = "complicationGlucose"
    private static let glucoseColorStringKey = "complicationGlucoseColorString"
    private static let trendKey = "complicationTrend"
    private static let dateKey = "complicationDate"

    static func save(_ complication: ComplicationGlucose) {
        save(
            glucose: complication.currentGlucose,
            glucoseColorString: complication.currentGlucoseColorString,
            trend: complication.trend,
            date: complication.date
        )
    }

    static func save(glucose: String, glucoseColorString: String?, trend: String?, date: Date) {
        guard glucose != "--" else { return }
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            Task {
                await WatchLogger.shared.log("⚠️ Failed to open UserDefaults for suite: \(appGroupId)")
            }
            return
        }
        defaults.set(glucose, forKey: glucoseKey)
        defaults.set(glucoseColorString ?? "#ffffff", forKey: glucoseColorStringKey)
        defaults.set(trend ?? "", forKey: trendKey)
        defaults.set(date.timeIntervalSince1970, forKey: dateKey)
        Task {
            await WatchLogger.shared
                .log(
                    "Saved complication values: glucose: \(glucose), glucoseColorString: \(glucoseColorString ?? "nil"), trend: \(trend ?? "nil"), date: \(date)"
                )
        }
    }

    static func load() -> ComplicationGlucose {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            Task {
                await WatchLogger.shared.log("⚠️ Loading complication data found no UserDefaults for suite: \(appGroupId)")
            }
            return .empty
        }
        let glucose = defaults.string(forKey: glucoseKey) ?? "--"
        let glucoseColorString = defaults.string(forKey: glucoseColorStringKey) ?? "#ffffff"
        let trend = defaults.string(forKey: trendKey) ?? ""
        let timestamp = defaults.double(forKey: dateKey)
        let date = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : Date.distantPast
        Task {
            await WatchLogger.shared
                .log(
                    "Loaded complication values: glucose: \(glucose), glucoseColorString: \(glucoseColorString), trend: \(trend), date: \(date)"
                )
        }
        return ComplicationGlucose(
            currentGlucose: glucose,
            currentGlucoseColorString: glucoseColorString,
            trend: trend,
            date: date
        )
    }
}
