import SwiftUI
import UIKit
import WidgetKit

// MARK: - Timeline Entry

struct TrioWatchComplicationEntry: TimelineEntry {
    let date: Date
    let data: ComplicationGlucose
}

// MARK: - Provider

struct TrioWatchComplicationProvider: TimelineProvider {
    private func fetchLatestEntry() -> TrioWatchComplicationEntry {
        let complication = WatchComplicationData.load()
        return TrioWatchComplicationEntry(date: Date(), data: complication)
    }

    func placeholder(in _: Context) -> TrioWatchComplicationEntry {
        TrioWatchComplicationEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TrioWatchComplicationEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(fetchLatestEntry())
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<TrioWatchComplicationEntry>) -> Void) {
        let entry = fetchLatestEntry()
        let reloadDate: Date
        if entry.data.isStale {
            reloadDate = Date().addingTimeInterval(5 * 60)
        } else {
            reloadDate = max(Date().addingTimeInterval(60), entry.data.staleDate)
        }
        let timeline = Timeline(entries: [entry], policy: .after(reloadDate))
        completion(timeline)
    }
}

// MARK: - Views

/// Root view dispatcher routing each widget family to its dedicated view
struct TrioWatchComplicationEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    var entry: TrioWatchComplicationEntry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            TrioAccessoryCircularView(entry: entry)
        case .accessoryCorner:
            TrioAccessoryCornerView(entry: entry)
        case .accessoryInline:
            TrioAccessoryInlineView(entry: entry)
        case .accessoryRectangular:
            TrioAccessoryRectangularView(entry: entry)
        default:
            Image("ComplicationIcon")
                .widgetAccentable()
                .widgetBackground(backgroundView: Color.clear)
        }
    }
}

/// Corner Complication: Curved glucose value with trend indicator in label
struct TrioAccessoryCornerView: View {
    let entry: TrioWatchComplicationEntry

    var body: some View {
        Text(entry.data.isStale ? "--" : entry.data.currentGlucose)
            .font(.system(.title3, design: .rounded, weight: .bold))
            .monospacedDigit()
            .widgetCurvesContent()
            .widgetLabel {
                if let rawValue = entry.data.direction?.rawValue {
                    Text(rawValue)
                }
            }
            .widgetAccentable()
            .widgetBackground(backgroundView: Color.clear)
    }
}

/// Circular Complication: Centered glucose value with trend arrow below
struct TrioAccessoryCircularView: View {
    let entry: TrioWatchComplicationEntry

    var body: some View {
        VStack(spacing: 0) {
            Text(entry.data.isStale ? "--" : entry.data.currentGlucose)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(entry.data.currentGlucoseColorString.toColor())
            Text(entry.data.trendArrow)
                .font(.system(.title, weight: .bold))
        }
        .widgetAccentable()
        .widgetBackground(backgroundView: Color.clear)
    }
}

/// Inline Complication: Single-line text for complications located above the watch face clock
struct TrioAccessoryInlineView: View {
    let entry: TrioWatchComplicationEntry

    var body: some View {
        let displayText: String = {
            if entry.data.isStale {
                return "Trio: --"
            }
            return entry.data.trendArrow.isEmpty
                ? "Trio: \(entry.data.currentGlucose)"
                : "Trio: \(entry.data.currentGlucose) \(entry.data.trendArrow)"
        }()
        Text(displayText)
    }
}

/// Rectangular Complication: Trio icon with prominent glucose value and trend arrow
struct TrioAccessoryRectangularView: View {
    let entry: TrioWatchComplicationEntry

    var body: some View {
        HStack(spacing: 6) {
            Image("ComplicationIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .widgetAccentable()

            Text(entry.data.isStale ? "--" : entry.data.currentGlucose)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()

            if !entry.data.trendArrow.isEmpty {
                Text(entry.data.trendArrow)
                    .font(.system(.body, weight: .bold))
            }

            Spacer()
        }
        .widgetBackground(backgroundView: Color.clear)
    }
}

// MARK: - Widget Configuration

@main struct TrioWatchComplication: Widget {
    let kind: String = "TrioWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrioWatchComplicationProvider()) { entry in
            TrioWatchComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Trio Glucose")
        .description("Displays the most recent blood glucose value and trend.")
        .supportedFamilies([
            .accessoryCorner,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

// MARK: - Helpers

extension View {
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(watchOS 10.0, iOSApplicationExtension 17.0, iOS 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

// MARK: - Previews

#if DEBUG
    struct TrioWatchComplication_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                TrioWatchComplicationEntryView(
                    entry: TrioWatchComplicationEntry(date: Date(), data: .placeholder)
                )
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")

                TrioWatchComplicationEntryView(
                    entry: TrioWatchComplicationEntry(date: Date(), data: .placeholder)
                )
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner")

                TrioWatchComplicationEntryView(
                    entry: TrioWatchComplicationEntry(date: Date(), data: .placeholder)
                )
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")

                TrioWatchComplicationEntryView(
                    entry: TrioWatchComplicationEntry(date: Date(), data: .placeholder)
                )
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular")
            }
        }
    }
#endif
