import Foundation
import CoreLocation

public class Initialization {
    public static let instance = Initialization()
    
    var defaultIcon:String?
    var storageName:String?
    var locationManager: CLLocationManager!
    
    public func configureFirebase(storageName:String) {
        self.storageName = storageName
        FirebaseApp.configure();
    }
    
    public func requestLocationAuthorization(delegate: CLLocationManagerDelegate) {
        locationManager = CLLocationManager()
        locationManager.delegate = delegate
        locationManager.requestAlwaysAuthorization()
    }
    
    public func setDefaultIconUrl(url:String) {
        defaultIcon = url
    }
    
    public func getDefaultIcon() -> String? {
        return defaultIcon
    }
    
    public func getStorageName() -> String? {
        return storageName
    }
}
