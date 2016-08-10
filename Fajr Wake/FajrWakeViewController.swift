//
//  FajrWakeViewController.swift
//  Fajr Wake
//
//  Created by Abidi on 6/14/16.
//  Copyright © 2016 Fajr Wake. All rights reserved.
//

import UIKit
import CoreLocation
import AddressBookUI
import AVFoundation

class FajrWakeViewController: UITableViewController, CLLocationManagerDelegate {
    var manager: OneShotLocationManager?
    var prayerTimes: [String: String] = [:]
    var locationNameDisplay: String?
    var alarms = [AlarmClockType]()
    var noAlarmsLabel = UILabel()
    var timer: NSTimer?
    var alarmSoundPlayer: AVAudioPlayer!
    var alarmAlertController: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPrayerTimes()
        noAlarmsLabelConfig()
        
        // hide "edit" button when no alarm
        if alarms.count > 0 {
            navigationItem.leftBarButtonItem = editButtonItem()
        } else {
            self.setEditing(false, animated: false)
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.setEditing(false, animated: false)
    }
    
    func noAlarmsLabelConfig() {
        noAlarmsLabel = UILabel(frame: CGRectZero)
        noAlarmsLabel.text = "No Alarms"
        noAlarmsLabel.baselineAdjustment = .AlignBaselines
        noAlarmsLabel.backgroundColor = UIColor.clearColor()
        noAlarmsLabel.textColor = UIColor.lightGrayColor()
        noAlarmsLabel.textAlignment = .Center
        noAlarmsLabel.font = UIFont(name: "Helvetica", size: 25.0)
        noAlarmsLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view!.addSubview(noAlarmsLabel)
        let xConstraint = NSLayoutConstraint(item: noAlarmsLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self.tableView, attribute: .CenterX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: noAlarmsLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.tableView, attribute: .CenterY, multiplier: 1, constant: -30.0)
        NSLayoutConstraint.activateConstraints([xConstraint, yConstraint])
    }
    
    func displaySettingsTableView() {
        if alarms.count == 0 {
            self.tableView.scrollEnabled = false
            self.noAlarmsLabel.hidden = false
        } else {
            self.tableView.scrollEnabled = true
            self.noAlarmsLabel.hidden = true
        }
    }
}

// MARK: - TableView
extension FajrWakeViewController {
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // hide "edit" button when no alarm
        if alarms.count > 0 {
            navigationItem.leftBarButtonItem = editButtonItem()
        } else {
            self.setEditing(false, animated: false)
            navigationItem.leftBarButtonItem = nil
        }
        
        return alarms.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        self.displaySettingsTableView()
        return 50.0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let fajr = prayerTimes[SalatsAndQadhas.Fajr.getString]
        let sunrise = prayerTimes[SalatsAndQadhas.Sunrise.getString]
        var toDisplay = ""
        if let fajrTime = fajr, let sunriseTime = sunrise, let locName = locationNameDisplay {
            toDisplay = "\(locName)\nFajr: \(fajrTime)\t\tSunrise: \(sunriseTime)"
        }
        return toDisplay
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = .Center
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "FajrWakeCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! FajrWakeCell
        var alarm = alarms[indexPath.row]
        
        cell.alarmLabel.attributedText = alarm.attributedTitle
        cell.alarmDetailLabel.attributedText = alarm.attributedSubtitle
        cell.editingAccessoryType = .DisclosureIndicator
        
        // Alarm Switch
        if alarm.alarmOn == true {
            cell.backgroundColor = UIColor.whiteColor()
            
            // Alarming ////////////////////////////////////////////////////////////////
            if alarm.alarmType == .FajrWakeAlarm {
                let fajrAlarm = alarm as! FajrWakeAlarm
                var dateToAlarm = fajrAlarm.timeToAlarm(getPrayerTimes(NSDate()))
                
                if dateToAlarm.timeIntervalSinceNow < 0 {
                    // based on next day's prayer times
                    dateToAlarm = fajrAlarm.timeToAlarm(getPrayerTimes(NSDate().dateByAddingTimeInterval(60 * 60 * 24)))
                }
                if let url = fajrAlarm.sound.alarmSound.URL {
                    alarm.startAlarm(self, selector: #selector(self.alarmAction), date: dateToAlarm, userInfo: [indexPath.row : url])
                } else {
                    alarm.startAlarm(self, selector: #selector(self.alarmAction), date: dateToAlarm, userInfo: indexPath.row)
                }
                
            } else if alarm.alarmType == .CustomAlarm {
                let customAlarm = alarm as! CustomAlarm
                let dateToAlarm = customAlarm.timeToAlarm(nil)
                
                if let url = customAlarm.sound.alarmSound.URL {
                    alarm.startAlarm(self, selector: #selector(self.alarmAction), date: dateToAlarm, userInfo: [indexPath : url])
                } else {
                    alarm.startAlarm(self, selector: #selector(self.alarmAction), date: dateToAlarm, userInfo: indexPath)
                }
            }
            ///////////////////////////////////////////////////////////////////////////

        } else {
            cell.backgroundColor = UIColor.groupTableViewBackgroundColor()
            alarm.stopAlarm()
        }
        let alarmSwitch = UISwitch(frame: CGRectZero)
        alarmSwitch.on = alarm.alarmOn
        cell.accessoryView = alarmSwitch
        alarmSwitch.tag = indexPath.row
        alarmSwitch.addTarget(self, action: #selector(self.switchChanged), forControlEvents: .ValueChanged)
        
        return cell
    }
    
    // Target-Action for AlarmClock switch (on/off)
    func switchChanged(switchControl: UISwitch) {
        let switchOriginInTableView = switchControl.convertPoint(CGPointZero, toView: tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(switchOriginInTableView) {
            alarms[indexPath.row].alarmOn = switchControl.on
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        } else {
            print("cell doesn't exist (it may have been deleted)")
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // remove NSTimer
            alarms[indexPath.row].alarmOn = false
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            // Delete the row from the data source
            alarms.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if tableView.editing == true {
            tableView.allowsSelectionDuringEditing = true
        } else {
            self.tableView.allowsSelection = false
        }
        return true
    }
}

// MARK: - Navigation
extension FajrWakeViewController {
    @IBAction func unwindToAlarms(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.sourceViewController as? AddAlarmMasterViewController, let alarm = sourceViewController.alarmClock {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // edit alarm
                // turn off the previous alarm
                alarms[selectedIndexPath.row].alarmOn = false
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
                
                // replace alarm clock with edited alarm
                alarms[selectedIndexPath.row] = alarm
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
            } else {
                // add new alarm
                let newIndexPath = NSIndexPath(forRow: alarms.count, inSection: 0)
                alarms.append(alarm)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
            }
        }
    }

    ///////////////////////////////Firing Alarm////////////////////////////////////////////////////
    func alarmAction(timer: NSTimer) {
        var url: NSURL?
        var indexPath: NSIndexPath?
        
        if let userInfo = timer.userInfo as? [NSIndexPath : NSURL] {
            indexPath = userInfo.first!.0
            url = userInfo.first!.1
        } else if let userInfo = timer.userInfo as? NSIndexPath {
            indexPath = userInfo
        }

        if url != nil {
            playSound(url!)
        }
        
        ///// Alarm Alert View
        alarmAlertController = UIAlertController(title: "\(alarms[indexPath!.row].alarmLabel)", message: nil, preferredStyle: .Alert)
        if alarms[indexPath!.row].snooze == true {
            // Snooze Button
            alarmAlertController!.addAction(UIAlertAction(title: "Snooze", style: UIAlertActionStyle.Default) {
                action -> Void in
                if self.alarmSoundPlayer != nil {
                    self.alarmSoundPlayer.stop()
                    self.alarmSoundPlayer = nil
                }
                // snooze for 10 mins
                if indexPath != nil {
                    if url != nil {
                        self.alarms[indexPath!.row].startAlarm(self, selector: #selector(self.alarmAction), date: NSDate().dateByAddingTimeInterval(60 * 10), userInfo: [indexPath!.row : url!])
                    } else {
                        self.alarms[indexPath!.row].startAlarm(self, selector: #selector(self.alarmAction), date: NSDate().dateByAddingTimeInterval(60 * 10), userInfo: indexPath!)
                    }
                } else {
                    print("invalid indexPath!")
                }
                })
        }
        // Ok Button
        alarmAlertController!.addAction(UIAlertAction(title: "OK", style: .Default) {
            action -> Void in
            if self.alarmSoundPlayer != nil {
                self.alarmSoundPlayer.stop()
                self.alarmSoundPlayer = nil
            }
            })
        self.presentViewController(alarmAlertController!, animated: true, completion: nil)
    }
    
    func playSound(url: NSURL) {
        do {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) // play audio even in silent mode
            } catch {
                print("could not play in silent mode")
            }
            alarmSoundPlayer = try AVAudioPlayer(contentsOfURL: url)
            alarmSoundPlayer.volume = 1.0
            alarmSoundPlayer.play()
            alarmSoundPlayer.numberOfLoops = -1 // "infinite" loop
        } catch {
            print("could not play sound")
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    
    @IBAction func unwindToAlarmsDelete(sender: UIStoryboardSegue) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            // remove NSTimer
            alarms[selectedIndexPath.row].alarmOn = false
            tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
            
            // delete cell
            alarms.removeAtIndex(selectedIndexPath.row)
            tableView.deleteRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let addAlarmMasterVC = (segue.destinationViewController as! UINavigationController).topViewController as! AddAlarmMasterViewController
            if let selectedAlarmCell = sender as? FajrWakeCell {
                let indexPath = tableView.indexPathForCell(selectedAlarmCell)!
                let selectedAlarm = alarms[indexPath.row]
                
                addAlarmMasterVC.navigationItem.title = "Edit Alarm"
                addAlarmMasterVC.alarmClock = selectedAlarm
            }
        } else if segue.identifier == "addItem" {
            // new alarm
        } else if segue.identifier == "settingsSegue" {
            let settingsVC = segue.destinationViewController as! SettingsViewController
            settingsVC.fajrWakeVCReference = self
        }
    }
}

// MARK: - Setups and Settings
extension FajrWakeViewController {
    // calls appropriate methods to perform specific tasks in order to populate prayertime dictionary
    func setupPrayerTimes() {
        if NSUserDefaults.standardUserDefaults().boolForKey("launchedBefore") == true {
            if let displayAddress = NSUserDefaults.standardUserDefaults().objectForKey("userAddressForDisplay") as? String {
                self.locationNameDisplay = displayAddress
            } else {
                self.locationNameDisplay = "Error with getting your city name"
            }
            updatePrayerTimes(NSDate())
            
        } else {
            startLocationDelegation()
            // once the app launched for first time, set "launchedBefore" to true
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "launchedBefore")
        }
    }
    
    // location settings for prayer time
    func locationSettingsForPrayerTimes (lat lat: Double, lon: Double, gmt: Double) {
        let settings = NSUserDefaults.standardUserDefaults()
        settings.setDouble(lat, forKey: "latitude")
        settings.setDouble(lon, forKey: "longitude")
        settings.setDouble(gmt, forKey: "gmt")
    }
    
    // update prayer time dictionary
    func updatePrayerTimes(date: NSDate) {
        self.prayerTimes = getPrayerTimes(date)
        self.tableView.reloadData()
    }
    
    // Helper method to get prayer times
    func getPrayerTimes(date: NSDate) -> [String: String] {
        let settings = NSUserDefaults.standardUserDefaults()
        let lon = settings.doubleForKey("longitude")
        let lat = settings.doubleForKey("latitude")
        let gmt = settings.doubleForKey("gmt")
        let userPrayerTime = UserSettingsPrayertimes()
        
        return userPrayerTime.getUserSettings().getPrayerTimes(NSCalendar.currentCalendar(), date: date, latitude: lat, longitude: lon, tZone: gmt)
    }
}

// MARK: - Get location
// Get coordinates and call functinos to get prayer times
extension FajrWakeViewController {
    func startLocationDelegation() {
        // Activity Indicator
        EZLoadingActivity.show("Getting your location...", disableUI: true)
        
        manager = OneShotLocationManager()
        manager!.fetchWithCompletion {location, error in
            
            // fetch location or an error
            if let loc = location {
                let lat = loc.coordinate.latitude
                let lon = loc.coordinate.longitude
                let gmt = LocalGMT.getLocalGMT()
                self.setupLocationForPrayerTimes(lat, lon: lon, gmt: gmt)
                // stop showing activity indicator (success)
                EZLoadingActivity.hide(success: true, animated: true)
            } else if let err = error {
                print(err.localizedDescription)
                // setting defaults to San Jose, CA, USA's time if error in getting user location
                let lat = 37.279518
                let lon = -121.867905
                let gmt = -7.0
                self.setupLocationForPrayerTimes(lat, lon: lon, gmt: gmt)
                
                if err.code == 0 {
                    let alertController = UIAlertController(
                        title: "Location Access Disabled",
                        message: "In order to setup your alarm, the app needs access to your location so that your local prayer times are determined. The app will use San Jose, CA, USA's prayer timing if you disable location access.",
                        preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                            UIApplication.sharedApplication().openURL(url)
                        }
                    }
                    alertController.addAction(openAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    let alertController = UIAlertController(title: "Could not get your location!", message: "Prayer times are now based on San Jose, CA, USA.", preferredStyle: .Alert)
                    let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    alertController.addAction(OKAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                // stop showing activity indicator (not successful)
                EZLoadingActivity.hide(success: false, animated: true)
            }
            self.manager = nil
        }
    }
    
    func setupLocationForPrayerTimes(lat: Double, lon: Double, gmt: Double) {
        // location settings for prayer times
        self.locationSettingsForPrayerTimes(lat: lat, lon: lon, gmt: gmt)
        // call "reverseGeocoding" to get city, state, and country of the given coordinates
        //   then update prayer times
        self.reverseGeocoding(lat, longitude: lon)
        self.updatePrayerTimes(NSDate())
    }
}

// MARK: - Geocoding
// to get coordinates and names of cities, states, and countries
extension FajrWakeViewController {
    // reverse geocoding to get address of user location for display
    func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print(error)
                let address = "Network Error"
                NSUserDefaults.standardUserDefaults().setObject(address, forKey: "userAddressForDisplay")
                self.locationNameDisplay = NSUserDefaults.standardUserDefaults().objectForKey("userAddressForDisplay") as? String
                return
            }
            else if placemarks?.count > 0 {
                self.setLocationAddress(placemarks!)
            }
        })
    }
    
    // sets locationNameDisplay variable appropriately
    func setLocationAddress(placemarks: [CLPlacemark]) {
        let pm = placemarks[0]
        var saveAddress = ""
        if let address = pm.addressDictionary as? [String: AnyObject] {
            if let city = address["City"], let state = address["State"], let country = address["Country"] {
                saveAddress = "\(String(city)), \(String(state)), \(String(country))"
            } else if let state = address["State"], let country = address["Country"] {
                saveAddress = "\(String(state)), \(String(country))"
            } else {
                if let country = address["Country"] {
                    saveAddress = "\(String(country))"
                }
            }
        } else {
            saveAddress = "Can't Find Your City Name"
        }
        NSUserDefaults.standardUserDefaults().setObject(saveAddress, forKey: "userAddressForDisplay")
        self.locationNameDisplay = NSUserDefaults.standardUserDefaults().objectForKey("userAddressForDisplay") as? String
    }
}