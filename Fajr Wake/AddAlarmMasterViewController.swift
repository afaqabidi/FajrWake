//
//  AddAlarmViewController.swift
//  Fajr Wake
//
//  Created by Abidi on 6/25/16.
//  Copyright © 2016 Fajr Wake. All rights reserved.
//

import UIKit

class AddAlarmMasterViewController: UIViewController {
    @IBOutlet weak var fajrAlarmContainer: UIView!
    @IBOutlet weak var customAlarmContainer: UIView!
    @IBOutlet weak var choicesTableViewContainer: UIView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var alarmClock: AlarmClockType?
    
    var alarmType: AlarmType? {
        didSet {
            if let alarmtype = alarmType {
                if alarmtype == .FajrWakeAlarm {
                    alphaSettingsForAlarmContainers(fajrAlpha: 1.0, customAlpha: 0.0)
                } else if alarmtype == .CustomAlarm {
                    alphaSettingsForAlarmContainers(fajrAlpha: 0.0, customAlpha: 1.0)
                }
            }
        }
    }
    var alarm: AlarmClockType?
    var alarmLabel: String?
    var daysToRepeat: [Days]?
    var sound: AlarmSound?
    var snooze: Bool?
    var minsToAdjust: Int?
    var whenToWake: WakeOptions?
    var whatSalatToWake: SalatsAndQadhas?

    override func viewDidLoad() {
        super.viewDidLoad()
        alphaSettingsForAlarmContainers(fajrAlpha: 1.0, customAlpha: 0.0)
    }
    
    @IBAction func cancel (sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func alphaSettingsForAlarmContainers(fajrAlpha fajrAlpha: CGFloat, customAlpha: CGFloat) {
        fajrAlarmContainer.alpha = fajrAlpha
        customAlarmContainer.alpha = customAlpha
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if saveButton === sender {
            if alarmType != nil {
                if alarmType! == .FajrWakeAlarm {
                    alarmClock = FajrWakeAlarm(alarmLabel: self.alarmLabel!, daysToRepeat: self.daysToRepeat, sound: self.sound!, snooze: snooze!, minsToAdjust: 0, whenToWake: .OnTime, whatSalatToWake: .Fajr, alarmType: self.alarmType!)
                } else if alarmType! == .CustomAlarm {
                    alarmClock = CustomAlarm(alarmLabel: self.alarmLabel!, daysToRepeat: self.daysToRepeat, sound: self.sound!, snooze: snooze!, time: NSDate(), alarmType: .CustomAlarm)
                }
            }
        }
        
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case "fajrWakePickerContainer":
                let fajrAlarmPickerVCContainer = segue.destinationViewController as! FajrAlarmPickerVCContainer
                fajrAlarmPickerVCContainer.AddAlarmMasterVCReference = self
//                fajrAlarmPickerVCContainer.setupFajrAlarm(minsToAdjust: minsToAdjust!, whenToAlarm: self.whenToWake!.rawValue, whatSalatToAlarm: whatSalatToWake!.rawValue)
            case "customAlarmPickerContainer":
                let customAlarmPickerVCContainer = segue.destinationViewController as! CustomAlarmPickerVCContainer
                customAlarmPickerVCContainer.AddAlarmMasterVCReference = self
            case "addAlarmChoicesContainer":
                let addAlarmChoicesContainer = segue.destinationViewController as! AddAlarmChoicesContainer
                addAlarmChoicesContainer.AddAlarmMasterVCReference = self
                
                // DEFAULTS or EDITS
                if let alarm = alarmClock {
                    if alarm.alarmType == .CustomAlarm {
                        if let customAlarm = alarm as? CustomAlarm {
                            alarmType = customAlarm.alarmType
                            daysToRepeat = customAlarm.daysToRepeat
                            alarmLabel = customAlarm.alarmLabel
                            sound = customAlarm.sound
                            snooze = customAlarm.snooze
                        }
                    } else if alarm.alarmType == .FajrWakeAlarm {
                        if let fajrWakeAlarm = alarm as? FajrWakeAlarm {
                            alarmType = fajrWakeAlarm.alarmType
                            daysToRepeat = fajrWakeAlarm.daysToRepeat
                            alarmLabel = fajrWakeAlarm.alarmLabel
                            sound = fajrWakeAlarm.sound
                            snooze = fajrWakeAlarm.snooze
                        }
                    }
                } else {
                    // DEFAULTS
                    alarmType = .FajrWakeAlarm
                    daysToRepeat = nil
                    alarmLabel = "Alarm"
                    let defaultSound = NSUserDefaults.standardUserDefaults().objectForKey("DefaultSound") as? String
                    let defaultSoundTitle = NSUserDefaults.standardUserDefaults().objectForKey("DefaultSoundTitle") as? String
                    sound = AlarmSound(alarmSound: AlarmSounds(rawValue: defaultSound!)!, alarmSectionTitle: AlarmSoundsSectionTitles(rawValue: defaultSoundTitle!)!)
                    snooze = true
                }
                
            default:
                break
            }
        }
    }
}