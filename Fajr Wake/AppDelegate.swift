//
//  AppDelegate.swift
//  Fajr Wake
//
//  Created by Abidi on 5/20/16.
//  Copyright © 2016 Fajr Wake. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var manager: OneShotLocationManager?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Default Settings for PrayerTimes
        if NSUserDefaults.standardUserDefaults().boolForKey("launchedBefore") == false {
            // set default settings for prayertimes
            let settings = NSUserDefaults.standardUserDefaults()
            settings.setInteger(7, forKey: PrayerTimeSettingsReference.CalculationMethod.rawValue)
            settings.setInteger(0, forKey: PrayerTimeSettingsReference.AsrJuristic.rawValue)
            settings.setInteger(0, forKey: PrayerTimeSettingsReference.AdjustHighLats.rawValue)
            settings.setInteger(1, forKey: PrayerTimeSettingsReference.TimeFormat.rawValue)
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

