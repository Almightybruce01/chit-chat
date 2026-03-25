import Foundation
import CoreLocation
import AVFoundation

final class AppPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var cameraGranted = false
    @Published var latestCity: String?

    private let locationManager = CLLocationManager()
    private var geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestAllPermissions() {
        requestLocationAccess()
        requestCameraAccess()
    }

    /// Call from the city picker — requests auth if needed, then a one-shot location fix for reverse geocoding.
    func requestLocationForCityOnly() {
        locationStatus = locationManager.authorizationStatus
        switch locationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            latestCity = nil
        @unknown default:
            break
        }
    }

    private func requestLocationAccess() {
        locationStatus = locationManager.authorizationStatus
        if locationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraGranted = granted
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            let city = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea
            DispatchQueue.main.async {
                self.latestCity = city
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal; app falls back to existing city preference.
    }
}
