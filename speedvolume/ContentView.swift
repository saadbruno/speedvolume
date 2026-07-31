//
//  ContentView.swift
//  speedvolume
//
//  Created by Bruno Saad Marques on 15/07/26.
//

import CoreLocation
import MediaPlayer
import SwiftUI

struct ContentView: View {
    @StateObject private var speedMonitor = SpeedMonitor()
    @State private var targetVolume: Float = 0.3
    @State private var volumeMode: VolumeMode = .low

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(speedMonitor.speedText)
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(volumeMode.textColor)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .contentTransition(.numericText(value: speedMonitor.speedMPH))
                    .animation(.snappy(duration: 0.2), value: speedMonitor.speedText)

                Text(speedMonitor.statusText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)

            SystemVolumeView(volume: targetVolume)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)
        }
        .onAppear {
            speedMonitor.start()
            updateVolumeMode(for: speedMonitor.speedMPH)
        }
        .onDisappear {
            speedMonitor.stop()
        }
        .onChange(of: speedMonitor.speedMPH) { _, speedMPH in
            updateVolumeMode(for: speedMPH)
        }
    }

    private func updateVolumeMode(for speedMPH: Double) {
        if speedMPH > 7 {
            setVolumeMode(.high)
        } else if speedMPH < 5 {
            setVolumeMode(.low)
        }
    }

    private func setVolumeMode(_ mode: VolumeMode) {
        guard volumeMode != mode else { return }

        volumeMode = mode
        targetVolume = mode.volume
    }
}

private enum VolumeMode {
    case high
    case low

    var volume: Float {
        switch self {
        case .high:
            return 1.0
        case .low:
            return 0.3
        }
    }

    var textColor: Color {
        switch self {
        case .high:
            return .white
        case .low:
            return .yellow
        }
    }
}

private final class SpeedMonitor: NSObject, ObservableObject {
    @Published private(set) var speedMPH = 0.0
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastError: String?

    private let locationManager = CLLocationManager()
    private let metersPerSecondToMilesPerHour = 2.2369362921

    var speedText: String {
        "\(speedMPH, specifier: "%.1f") mph"
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

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .fitness
        locationManager.distanceFilter = kCLDistanceFilterNone
        authorizationStatus = locationManager.authorizationStatus
    }

    func start() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
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

private struct SystemVolumeView: UIViewRepresentable {
    let volume: Float

    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.showsRouteButton = false
        volumeView.showsVolumeSlider = true
        return volumeView
    }

    func updateUIView(_ volumeView: MPVolumeView, context: Context) {
        setVolume(volume, in: volumeView)
    }

    private func setVolume(_ volume: Float, in volumeView: MPVolumeView) {
        let clampedVolume = min(max(volume, 0), 1)

        if let slider = volumeView.volumeSlider {
            slider.setValue(clampedVolume, animated: false)
            slider.sendActions(for: .touchUpInside)
        } else {
            DispatchQueue.main.async {
                setVolume(clampedVolume, in: volumeView)
            }
        }
    }
}

private extension MPVolumeView {
    var volumeSlider: UISlider? {
        subviews.compactMap { $0 as? UISlider }.first
    }
}

#Preview {
    ContentView()
}
