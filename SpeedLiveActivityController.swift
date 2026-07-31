//
//  SpeedLiveActivityController.swift
//  speedvolume
//
//  Created by Bruno Saad Marques on 15/07/26.
//

import ActivityKit
import Foundation
import Observation

@Observable
final class SpeedLiveActivityController {
    private(set) var isRunning = false
    private(set) var statusText = "Live Activity inativa."

    private var activity: Activity<SpeedActivityAttributes>?

    func startOrUpdate(speedMPH: Double, isDuckingEnabled: Bool) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusText = "Live Activities desativadas nos Ajustes."
            isRunning = false
            return
        }

        if activity == nil {
            activity = Activity<SpeedActivityAttributes>.activities.first
        }

        guard let activity else {
            await start(speedMPH: speedMPH, isDuckingEnabled: isDuckingEnabled)
            return
        }

        await update(activity, speedMPH: speedMPH, isDuckingEnabled: isDuckingEnabled)
    }

    func end() async {
        guard let activity else { return }

        let content = ActivityContent(
            state: SpeedActivityAttributes.ContentState(
                speedMPH: 0,
                isDuckingEnabled: false,
                updatedAt: Date()
            ),
            staleDate: nil
        )

        await activity.end(content, dismissalPolicy: .immediate)
        self.activity = nil
        isRunning = false
        statusText = "Live Activity encerrada."
    }

    private func start(speedMPH: Double, isDuckingEnabled: Bool) async {
        let attributes = SpeedActivityAttributes(title: "Speed Volume")
        let content = ActivityContent(
            state: SpeedActivityAttributes.ContentState(
                speedMPH: speedMPH,
                isDuckingEnabled: isDuckingEnabled,
                updatedAt: Date()
            ),
            staleDate: Date().addingTimeInterval(30),
            relevanceScore: 100
        )

        do {
            activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            isRunning = true
            statusText = "Live Activity ativa."
        } catch {
            isRunning = false
            statusText = "Nao foi possivel iniciar a Live Activity."
        }
    }

    private func update(
        _ activity: Activity<SpeedActivityAttributes>,
        speedMPH: Double,
        isDuckingEnabled: Bool
    ) async {
        let content = ActivityContent(
            state: SpeedActivityAttributes.ContentState(
                speedMPH: speedMPH,
                isDuckingEnabled: isDuckingEnabled,
                updatedAt: Date()
            ),
            staleDate: Date().addingTimeInterval(30),
            relevanceScore: 100
        )

        await activity.update(content)
        isRunning = true
        statusText = "Live Activity atualizada."
    }
}
