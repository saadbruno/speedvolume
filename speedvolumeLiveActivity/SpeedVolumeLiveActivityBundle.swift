//
//  SpeedVolumeLiveActivityBundle.swift
//  speedvolumeLiveActivity
//
//  Created by Bruno Saad Marques on 15/07/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

@main
struct SpeedVolumeLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        SpeedVolumeLiveActivity()
    }
}

struct SpeedVolumeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpeedActivityAttributes.self) { context in
            SpeedLiveActivityView(state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(context.state.isDuckingEnabled ? .yellow : .white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    SpeedLiveActivityView(state: context.state)
                }
            } compactLeading: {
                Text(context.state.compactSpeedText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(context.state.isDuckingEnabled ? .yellow : .white)
                    .minimumScaleFactor(0.75)
            } compactTrailing: {
                Text("mph")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            } minimal: {
                Text(context.state.compactSpeedText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(context.state.isDuckingEnabled ? .yellow : .white)
                    .minimumScaleFactor(0.7)
            }
            .widgetURL(URL(string: "speedvolume://speed"))
        }
    }
}

private struct SpeedLiveActivityView: View {
    let state: SpeedActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 8) {
            Text(state.speedText)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(state.isDuckingEnabled ? .yellow : .white)
                .minimumScaleFactor(0.65)
                .lineLimit(1)

            Text(state.duckingText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

#Preview("Lock Screen", as: .content, using: SpeedActivityAttributes(title: "Speed Volume")) {
    SpeedVolumeLiveActivity()
} contentStates: {
    SpeedActivityAttributes.ContentState(speedMPH: 12.3, isDuckingEnabled: false, updatedAt: Date())
    SpeedActivityAttributes.ContentState(speedMPH: 4.8, isDuckingEnabled: true, updatedAt: Date())
}
