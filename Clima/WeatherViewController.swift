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
    let localhost = "https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fwww.meteoalarm.eu%2Fdocuments%2Frss%2Fbg%2FBG015.rss&api_key=uheaucy4amxjplfmxiojxmn1ddkoudzrxu6toncc"

    //Instance variables
    let locationManager = CLLocationManager()
    let weatherDataModer = WeatherDataModel()
    
    var location = CLLocation()
    
    //Pre-linked IBOutlets
    //@IBOutlet weak var liquidView: UIView!
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
        locationManager.startUpdatingLocation()
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        let fluidView = BAFluidView.init(frame: self.view.frame, startElevation: 0.5)
        fluidView?.fillColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        fluidView?.alpha = 0.5
        fluidView?.startAnimation()
        fluidView?.startTiltAnimation()
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

    
    func testJson(json: JSON) {
        let summary = json["items"][0]["description"].stringValue
        let str = summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        let removeDays = str.replacingOccurrences(of: "Today", with: "")
        warningLabel.text = removeDays
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
    
            Alamofire.request(requestUrl).responseJSON { (response) in
                if response.result.isSuccess {
                    print(response.result.value!)
                    let weatherJSON : JSON = JSON(response.result.value!)
                    //self.updateWeatherData(json: weatherJSON)
                    self.updateWeatherData(json: weatherJSON)
                    
                } else {
                    print("Fail")
                }
            }
        }
    }
    
    //MARK: - UI Updates
    /***************************************************************/
    func updateLabels(tempToCheck: Double, labelToUpdate: UILabel) {
        if tempToCheck <= 20 {
            labelToUpdate.text = "LOW"
            backgroundView.backgroundColor = UIColor(red: 42/255, green: 208/255, blue: 255/255, alpha: 1.0)
        } else if tempToCheck > 20 && tempToCheck <= 60 {
            labelToUpdate.text = "MEDIUM"
            backgroundView.backgroundColor = UIColor(red: 255/255, green: 176/255, blue: 106/255, alpha: 1.0)
        } else {
            labelToUpdate.text = "HIGH"
            backgroundView.backgroundColor = UIColor(red: 255/255, green: 145/255, blue: 131/255, alpha: 1.0)
        }
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


