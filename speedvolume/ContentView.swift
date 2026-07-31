//
//  ContentView.swift
//  speedvolume
//
//  Created by Bruno Saad Marques on 15/07/26.
//

import CoreLocation
import Foundation
import AVFAudio
import Observation
import SwiftUI

struct ContentView: View {
    @State private var speedMonitor: SpeedMonitor
    @State private var audioDucking: AudioDuckingController
    @State private var liveActivity: SpeedLiveActivityController
    @State private var audioMode: SpeedAudioMode = .duckingEnabled

    init(
        speedMonitor: SpeedMonitor = SpeedMonitor(),
        audioDucking: AudioDuckingController = AudioDuckingController(),
        liveActivity: SpeedLiveActivityController = SpeedLiveActivityController()
    ) {
        self.speedMonitor = speedMonitor
        self.audioDucking = audioDucking
        self.liveActivity = liveActivity
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(speedMonitor.speedText)
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(audioMode.textColor)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .contentTransition(.numericText(value: speedMonitor.speedMPH))
                    .animation(.snappy(duration: 0.2), value: speedMonitor.speedText)

                Text(speedMonitor.statusText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(speedMonitor.backgroundStatusText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(audioDucking.statusText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(liveActivity.statusText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            speedMonitor.start()
            updateAudioMode(for: speedMonitor.speedMPH)
        }
        .onDisappear {
            speedMonitor.prepareForViewDisappearance()
        }
        .onChange(of: speedMonitor.speedMPH) { _, speedMPH in
            updateAudioMode(for: speedMPH)
        }
        .task(id: liveActivityUpdateID) {
            await liveActivity.startOrUpdate(
                speedMPH: speedMonitor.speedMPH,
                isDuckingEnabled: audioMode.isDuckingEnabled
            )
        }
    }

    private var liveActivityUpdateID: String {
        "\(speedMonitor.speedText)-\(audioMode.isDuckingEnabled)"
    }

    private func updateAudioMode(for speedMPH: Double) {
        if speedMPH > 7 {
            setAudioMode(.duckingDisabled)
        } else if speedMPH < 5 {
            setAudioMode(.duckingEnabled)
        }
    }

    private func setAudioMode(_ mode: SpeedAudioMode) {
        audioMode = mode
        audioDucking.setDuckingEnabled(mode.isDuckingEnabled)
    }
}

private enum SpeedAudioMode {
    case duckingDisabled
    case duckingEnabled

    var isDuckingEnabled: Bool {
        switch self {
        case .duckingDisabled:
            return false
        case .duckingEnabled:
            return true
        }
    }

    var textColor: Color {
        switch self {
        case .duckingDisabled:
            return .white
        case .duckingEnabled:
            return .yellow
        }
    }
}

@Observable
final class AudioDuckingController {
    private(set) var isDuckingEnabled = false
    private(set) var lastError: String?

    private let session = AVAudioSession.sharedInstance()

    var statusText: String {
        if let lastError {
            return lastError
        }

        return isDuckingEnabled ? "Audio ducking ativado." : "Audio ducking desativado."
    }

    func setDuckingEnabled(_ isEnabled: Bool) {
        isEnabled ? enableDucking() : disableDucking()
    }

    func enableDucking() {
        guard !isDuckingEnabled else { return }

        do {
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            isDuckingEnabled = true
            lastError = nil
        } catch {
            lastError = "Nao foi possivel ativar o audio ducking."
        }
    }

    func disableDucking() {
        guard isDuckingEnabled else { return }

        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            isDuckingEnabled = false
            lastError = nil
        } catch {
            lastError = "Nao foi possivel desativar o audio ducking."
        }
    }
}

@Observable
final class SpeedMonitor: NSObject {
    private(set) var speedMPH = 0.0
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var lastError: String?
    private(set) var isBackgroundLocationEnabled = false

    private let locationManager = CLLocationManager()
    private let metersPerSecondToMilesPerHour = 2.2369362921
    private let supportsBackgroundLocation = Bundle.main.supportsBackgroundLocationUpdates

    var speedText: String {
        String(format: "%.1f mph", speedMPH)
    }

    var statusText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Permita acesso a localizacao para medir a velocidade."
        case .restricted, .denied:
            return "Ative a permissao de localizacao nos Ajustes."
        case .authorizedAlways, .authorizedWhenInUse:
            return lastError ?? "Monitorando velocidade por GPS."
        @unknown default:
            return "Status de localizacao desconhecido."
        }
    }

    var backgroundStatusText: String {
        if supportsBackgroundLocation {
            return isBackgroundLocationEnabled ? "GPS em plano de fundo ativado." : "Preparando GPS em plano de fundo."
        }

        return "Para plano de fundo, ative Background Modes > Location updates no target."
    }

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .fitness
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestPermissionOnLaunch() {
        authorizationStatus = locationManager.authorizationStatus

        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func start() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            enableBackgroundLocationIfAvailable()
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            stop()
        @unknown default:
            stop()
        }
    }

    func stop() {
        locationManager.stopUpdatingLocation()
    }

    func stopForUserTermination() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        isBackgroundLocationEnabled = false
        speedMPH = 0
        lastError = nil
    }

    func prepareForViewDisappearance() {
        if !supportsBackgroundLocation {
            stop()
        }
    }

    private func enableBackgroundLocationIfAvailable() {
        guard supportsBackgroundLocation else {
            isBackgroundLocationEnabled = false
            return
        }

        locationManager.allowsBackgroundLocationUpdates = true
        isBackgroundLocationEnabled = true
    }
}

extension SpeedMonitor: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        lastError = nil
        start()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        lastError = nil
        speedMPH = max(location.speed, 0) * metersPerSecondToMilesPerHour
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = "Aguardando sinal de GPS."
    }
}

private extension Bundle {
    var supportsBackgroundLocationUpdates: Bool {
        guard let backgroundModes = object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
            return false
        }

        return backgroundModes.contains("location")
    }
}

#Preview {
    ContentView()
}
