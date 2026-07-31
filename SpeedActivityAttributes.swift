//
//  SpeedActivityAttributes.swift
//  speedvolume
//
//  Created by Bruno Saad Marques on 15/07/26.
//

import ActivityKit
import Foundation

struct SpeedActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let speedMPH: Double
        let isDuckingEnabled: Bool
        let updatedAt: Date

        var speedText: String {
            String(format: "%.1f mph", speedMPH)
        }

        var compactSpeedText: String {
            String(format: "%.1f", speedMPH)
        }

        var duckingText: String {
            isDuckingEnabled ? "Ducking ativado" : "Ducking desativado"
        }
    }

    let title: String
}
