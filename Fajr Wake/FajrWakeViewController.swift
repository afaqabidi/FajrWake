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
    var locationNameDisplay: String = ""
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
        updatePrayerTimes()
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
        return 30.0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let fajr = prayerTimes[SalatsAndQadhas.Fajr.getString]
        let sunrise = prayerTimes[SalatsAndQadhas.Sunrise.getString]
        var toDisplay = ""
        if let fajrTime = fajr, let sunriseTime = sunrise {
            toDisplay = "Fajr: \(fajrTime)\t\tSunrise: \(sunriseTime)"
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
                if let url = fajrAlarm.sound.alarmSound.URL {
                    alarm.startAlarm(self, selector: #selector(self.alarmAction), date: fajrAlarm.timeToAlarm(prayerTimes)!, userInfo: [indexPath.row : url])
                } else {
                    alarm.startAlarm(self, selector: #selector(self.alarmAction), date: fajrAlarm.timeToAlarm(prayerTimes)!, userInfo: indexPath.row)
                }

            } else if alarm.alarmType == .CustomAlarm {
                let customAlarm = alarm as! CustomAlarm
                if let url = customAlarm.sound.alarmSound.URL {
                    alarm.startAlarm(self, selector: #selector(self.alarmAction), date: customAlarm.timeToAlarm(nil)!, userInfo: [indexPath.row : url])
                } else {
                    alarm.startAlarm(self, selector: #selector(self.alarmAction), date: customAlarm.timeToAlarm(nil)!, userInfo: indexPath.row)
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
                alarms[selectedIndexPath.row] = alarm
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
            } else {
                // add new alarm
                let newIndexPath = NSIndexPath(forRow: alarms.count, inSection: 0)
                alarms.append(alarm)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
            }
        }
    }

    ///////////////////////////////Firing Alarm////////////////////////////////////////////////////
    func alarmAction(timer: NSTimer) {

        var url: NSURL?
        var row: Int?
        
        if let userInfo = timer.userInfo as? [Int : NSURL] {
            row = userInfo.first!.0
            url = userInfo.first!.1
        } else if let userInfo = timer.userInfo as? Int {
            row = userInfo
        }

        if url != nil {
            playSound(url!)
        }
        
        ///// Alarm Alert View
        alarmAlertController = UIAlertController(title: "Alarm", message: nil, preferredStyle: .Alert)
        // Snooze Button
        alarmAlertController!.addAction(UIAlertAction(title: "Snooze", style: UIAlertActionStyle.Default) {
            action -> Void in
            if self.alarmSoundPlayer != nil {
                self.alarmSoundPlayer.stop()
                self.alarmSoundPlayer = nil
            }
            
            if row != nil {
                if url != nil {
                    self.alarms[row!].startAlarm(self, selector: #selector(self.alarmAction), date: NSDate().dateByAddingTimeInterval(5), userInfo: [row! : url!])
                } else {
                    self.alarms[row!].startAlarm(self, selector: #selector(self.alarmAction), date: NSDate().dateByAddingTimeInterval(5), userInfo: row!)
                }
            } else {
                print("invalid timer row!")
            }
            })
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
            alarms.removeAtIndex(selectedIndexPath.row)
            tableView.deleteRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Fade)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let addAlarmMasterVC = (segue.destinationViewController as! UINavigationController).topViewController as! AddAlarmMasterViewController
            if let selectedAlarmCell = sender as? FajrWakeCell {
                // FIXME: - change navigation title of top to "Edit Item"
                let indexPath = tableView.indexPathForCell(selectedAlarmCell)!
                let selectedAlarm = alarms[indexPath.row]
                addAlarmMasterVC.alarmClock = selectedAlarm
            }
        } else if segue.identifier == "addItem" {
            // new alarm
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
                self.locationNameDisplay = "Could not get name of your city, state or country"
            }
            updatePrayerTimes()
            
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
    func updatePrayerTimes() {
        let settings = NSUserDefaults.standardUserDefaults()
        let lon = settings.doubleForKey("longitude")
        let lat = settings.doubleForKey("latitude")
        let gmt = settings.doubleForKey("gmt")
        
        let userPrayerTime = UserSettingsPrayertimes()
        self.prayerTimes = userPrayerTime.getUserSettings().getPrayerTimes(NSCalendar.currentCalendar(), latitude: lat, longitude: lon, tZone: gmt)
        
        self.tableView.reloadData()
    }
}

// MARK: - Get location
// Get coordinates and call functinos to get prayer times
extension FajrWakeViewController {
    func startLocationDelegation() {
        self.navigationItem.titleView = ActivityIndicator.showActivityIndicator("Getting location...")
        manager = OneShotLocationManager()
        manager!.fetchWithCompletion {location, error in
            
            // fetch location or an error
            if let loc = location {
                let lat = loc.coordinate.latitude
                let lon = loc.coordinate.longitude
                let gmt = LocalGMT.getLocalGMT()
                
                self.setupLocationForPrayerTimes(lat, lon: lon, gmt: gmt)
                
            } else if let err = error {
                print(err.localizedDescription)
                
                // setting defaults to Qom's time if error in getting user location
                let lat = 34.6476568
                let lon = 50.8789548
                let gmt = +4.5
                
                self.setupLocationForPrayerTimes(lat, lon: lon, gmt: gmt)
            }
            self.manager = nil
        }
    }
    
    func setupLocationForPrayerTimes(lat: Double, lon: Double, gmt: Double) {
        // location settings for prayer times
        self.locationSettingsForPrayerTimes(lat: lat, lon: lon, gmt: gmt)
        
        // call function to get city, state, and country of the given coordinates
        self.reverseGeocoding(lat, longitude: lon)
        
        self.updatePrayerTimes()
        
        // stop showing activity indicator in navigation title
        self.navigationItem.titleView = nil
    }
}

// MARK: - Geocoding
// to get coordinates and names of cities, states, and countries
extension FajrWakeViewController {
    // reverse geocoding to get address of user location for display
    func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // FIXME: Indicates user if network fail
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print(error)
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
            saveAddress = "could not get name of the user's city or country of their location"
        }
        NSUserDefaults.standardUserDefaults().setObject(saveAddress, forKey: "userAddressForDisplay")
        self.locationNameDisplay = NSUserDefaults.standardUserDefaults().objectForKey("userAddressForDisplay") as! String
    }
}