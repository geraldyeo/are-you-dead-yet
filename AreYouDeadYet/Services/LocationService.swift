import Foundation
import CoreLocation

class LocationService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var currentLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private var locationCompletion: ((CLLocation?) -> Void)?

    var authorizationStatus: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Not Set"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        updateAuthorizationStatus()
    }

    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        locationCompletion = completion

        if isAuthorized {
            locationManager.requestLocation()
        } else {
            completion(nil)
        }
    }

    private func updateAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        locationCompletion?(locations.last)
        locationCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        locationCompletion?(nil)
        locationCompletion = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus()
    }
}
