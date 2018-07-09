//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON
import UserNotifications
import BAFluidView
import CoreMotion

class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
    //Constants
    let WEATHER_URL = "https://api.darksky.net/forecast/"
    let APP_ID = "a039ffe9207798ea3e6337090c95e37f"
    let CITYAPI = "jkj8BLcguK1yGPne0hoern7Ts8NbiDCe"

    //Instance variables
    let locationManager = CLLocationManager()
    let weatherDataModer = WeatherDataModel()
    
    var location = CLLocation()
    var showPercent = true
    
    //Pre-linked IBOutlets
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var liquidView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var laterTempLabel: UILabel!
    @IBOutlet var backgroundView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting up Notifications
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound];
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
            }
        }
        
        // Setting up Location Manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestWhenInUseAuthorization()
        
        
        // Setup Swipe Gesture Recognizer
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector (handleSwipes(sender:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector (handleSwipes(sender:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
 
    
    //MARK: - Networking
    /***************************************************************/



    
    //MARK: - JSON Parsing
    /***************************************************************/
   
    
    //Write the updateWeatherData method here:
  
    
    func updateWeatherData(json: JSON) {
        let tempResult = json["currently"]["precipProbability"].double
        let currentlyMultiplied = tempResult! * 100
        
        updateLabels(tempToCheck: currentlyMultiplied, labelToUpdate: temperatureLabel)
        addFluidVIew(withElevation: tempResult! as NSNumber)
        let laterTempResult = json["hourly"]["data"][3]["precipProbability"].double
        let laterMultiplied = laterTempResult! * 100
        
        updateLabels(tempToCheck: laterMultiplied, labelToUpdate: laterTempLabel)

        let warningLabelResult = json["hourly"]["summary"].stringValue
        warningLabel.text = "\(warningLabelResult)"

        let content = UNMutableNotificationContent()
        content.title = "Hey! You should expect some rain soon! :) "
        content.body = "There is \(laterTempResult! * 100)% chance of rain in a few hours"
        content.sound = UNNotificationSound.default()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5,
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: "Alert", content: content, trigger: trigger)

        if Int(tempResult! * 100) > 50 {
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    func updateCityData(json: JSON) {
        let cityName = json["results"][0]["locations"][0]["adminArea5"].stringValue
        cityNameLabel.text = "\(cityName)"
    }
    func checkIfEventOccured() {
        locationManager.startUpdatingLocation()
        updateLocation()
    }
    
    func updateLocation() {
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            print("\(location.coordinate.latitude) :: \(location.coordinate.longitude)")
            
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            
            let requestUrl = "\(WEATHER_URL)\(APP_ID)/\(latitude),\(longitude)"
            //let requestUrl = "\(localhost)"
            let findCityUrl = "https://www.mapquestapi.com/geocoding/v1/reverse?key=\(CITYAPI)&location=\(latitude),\(longitude)&includeRoadMetadata=true&includeNearestIntersection=true"
         
            Alamofire.request(requestUrl).responseJSON { (response) in
                if response.result.isSuccess {
                    //print(response.result.value!)
                    let weatherJSON : JSON = JSON(response.result.value!)
                    //self.updateWeatherData(json: weatherJSON)
                    self.updateWeatherData(json: weatherJSON)
                    
                } else {
                    print("Fail")
                }
            }
            
            Alamofire.request(findCityUrl).responseJSON { (cityData) in
                if cityData.result.isSuccess {
                    print(cityData.result.value!)
                    let cityJSON : JSON = JSON(cityData.result.value!)
                    self.updateCityData(json: cityJSON)
                }
            }
            
        }
    }
    
    
    //MARK: - UI Updates
    /***************************************************************/
    func updateLabels(tempToCheck: Double, labelToUpdate: UILabel) {
  
        
        if tempToCheck <= 20 {
            labelToUpdate.leftToRightAnimation()
            labelToUpdate.text = showPercent == true ? "LO" : "\(tempToCheck)%"
            backgroundView.backgroundColor = UIColor(red: 42/255, green: 208/255, blue: 255/255, alpha: 1.0)
        } else if tempToCheck > 20 && tempToCheck <= 60 {
            labelToUpdate.text = showPercent == true ? "MED" : "\(tempToCheck)%"
            backgroundView.backgroundColor = UIColor(red: 255/255, green: 176/255, blue: 106/255, alpha: 1.0)
        } else {
             labelToUpdate.text = showPercent == true ? "HI" : "\(tempToCheck)%"
            backgroundView.backgroundColor = UIColor(red: 255/255, green: 145/255, blue: 131/255, alpha: 1.0)
        }
        
    }
    
    @objc func handleSwipes(sender: UISwipeGestureRecognizer) {
            if sender.direction == .right {
            showPercent = showPercent == true ? false : true
            updateLocation()
        }
    }
    
    func addFluidVIew(withElevation: NSNumber) {
        let fluidView = BAFluidView.init(frame: self.view.frame, startElevation: withElevation)
        fluidView?.fillColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        fluidView?.alpha = 0.5
        fluidView?.startAnimation()
        fluidView?.startTiltAnimation()
        //self.backgroundView.addSubview(fluidView!)
    }
    
    
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations[locations.count - 1]
        updateLocation()
    }
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    

    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    // TODO...
    

    
    //Write the PrepareForSegue Method here
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            //destinationVC.delegate = self
        }
        
    }
}

    // MARK: - Adding Swipe Animation To The Temperature Labels
extension UILabel {
    func leftToRightAnimation(duration: TimeInterval = 0.5, completionDelegate: AnyObject? = nil) {
        // Create a CATransition object
        let leftToRightTransition = CATransition()
        
        // Set its callback delegate to the completionDelegate that was provided
        if let delegate: AnyObject = completionDelegate {
            leftToRightTransition.delegate = delegate as! CAAnimationDelegate
        }
        
        leftToRightTransition.type = kCATransitionPush
        leftToRightTransition.subtype = kCATransitionFromLeft
        leftToRightTransition.duration = duration
        leftToRightTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        leftToRightTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        self.layer.add(leftToRightTransition, forKey: "leftToRightTransition")
    }
}

