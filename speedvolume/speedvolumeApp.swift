//
//  speedvolumeApp.swift
//  speedvolume
//
//  Created by Bruno Saad Marques on 15/07/26.
//

import SwiftUI

@main
struct speedvolumeApp: App {
    @State private var speedMonitor = SpeedMonitor()
    @State private var audioDucking = AudioDuckingController()
    @State private var liveActivity = SpeedLiveActivityController()

    var body: some Scene {
        WindowGroup {
            ContentView(
                speedMonitor: speedMonitor,
                audioDucking: audioDucking,
                liveActivity: liveActivity
            )
                .task {
                    speedMonitor.requestPermissionOnLaunch()
                    speedMonitor.start()
                    await liveActivity.startOrUpdate(
                        speedMPH: speedMonitor.speedMPH,
                        isDuckingEnabled: true
                    )
                }
        }
    }
}
