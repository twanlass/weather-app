//
//  ViewController.swift
//  Weather App
//
//  Created by Tyler Wanlass on 11/22/14.
//  Copyright (c) 2014 tdub. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var cityStateLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    private let apiKey = "871c70c06c7a65c7deb7c7af478377bd"
    
    var locationManager: CLLocationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observe state change - when app becomes active get latest weather data
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "updateAppBecameActive",
            name: "appBecameActive",
            object: nil
        )
    }
    
    func updateAppBecameActive() -> Void {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            
            if (locationManager.location != nil) {
                println("using cached location")
                userLocationUpdated()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            println("first time auth request...")
            locationManager.requestWhenInUseAuthorization()
        }
        
        if status == .Authorized || status == .AuthorizedWhenInUse {
            println("status changed to auth'd")
            locationManager.startMonitoringSignificantLocationChanges()
        }
        
        if status == .Restricted || status == .Denied {
            // Need to add messaging to user that location services are required
            println("location services denied for app")
        }
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        println("using newly updated location")
        userLocationUpdated()
    }
    
    func locationManager(manager:CLLocationManager, didFailWithError error:NSError!) {
        println("whoops! location error")
    }

    func locationManager(manager:CLLocationManager, didFinishDeferredUpdatesWithError error:NSError!) {
        println("whoops! location error")
    }
    
    func getCurrentWeatherData(lat: CLLocationDegrees, lon: CLLocationDegrees) -> Void {
        var latValue : String = "\(lat)"
        var lonValue : String = "\(lon)"
        
        let baseURL = NSURL(string: "https://api.forecast.io/forecast/\(apiKey)/")
        let forecastURL = NSURL(string: "\(lonValue),\(latValue)", relativeToURL: baseURL)
        
        let sharedSession = NSURLSession.sharedSession()
        let downloadTask: NSURLSessionDownloadTask =
        sharedSession.downloadTaskWithURL(forecastURL!, completionHandler: {(location: NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
            
            if (error == nil){
                let dataObject = NSData(contentsOfURL: location)
                let weatherDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(dataObject!, options: nil, error: nil) as NSDictionary
                
                let currentWeather = Current(weatherDictionary: weatherDictionary)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.temperatureLabel.text = "\(currentWeather.temperature)"
                    self.iconView.image = currentWeather.icon!
                    self.currentTimeLabel.text = "As of \(currentWeather.currentTime!)"
                    self.summaryLabel.text = "\(currentWeather.summary)"
                })
            } else {
                let networkIssueController = UIAlertController(
                    title: "Uh oh!",
                    message: "Unable to get latest weather.",
                    preferredStyle: .Alert
                )
                
                let okButton = UIAlertAction(
                    title: "OK",
                    style: .Default,
                    handler: nil
                )
                networkIssueController.addAction(okButton)
                
                let cancelButton = UIAlertAction(
                    title: "Cancel",
                    style: .Cancel,
                    handler: nil
                )
                networkIssueController.addAction(cancelButton)
            
                self.presentViewController(
                    networkIssueController,
                    animated: true,
                    completion: nil
                )
            }
        })
        
        downloadTask.resume()
    }
    
    func userLocationUpdated() -> Void {
        var lat = locationManager.location.coordinate.longitude
        var lon = locationManager.location.coordinate.latitude
        getCurrentWeatherData(lat, lon: lon)
        getUserCityStateString()
    }
    
    func getUserCityStateString() -> Void {
        CLGeocoder().reverseGeocodeLocation(locationManager.location, completionHandler: {(placemarks, error) -> Void in
            if error == nil && placemarks.count > 0 {
                let pm = placemarks[0] as CLPlacemark
                self.updateUserCityStateString(pm)
            } else {
                println("error returning address info from coords")
            }
        })
    }
    
    func updateUserCityStateString(placemark: CLPlacemark) -> Void {
        var userState : String?
        var userCity :  String?
            
        if(placemark.locality != nil) {
            userCity = placemark.locality
        }
        
        if(placemark.administrativeArea != nil){
            userState =  placemark.administrativeArea
        }
        
        cityStateLabel.text = "\(userCity!), \(userState!)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
