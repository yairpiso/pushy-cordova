//
//  PushyPlugin.swift
//  Pushy
//
//  Created by Pushy on 13/4/18.
//  Copyright © 2018 Pushy. All rights reserved.
//

@objc(PushyPlugin) class PushyPlugin : CDVPlugin {
    var pushy: Pushy?
    var hasStartupNotification = false
    var startupNotification: [AnyHashable : Any]?
    var notificationClickCallback: CDVInvokedUrlCommand?
    
    func getPushyInstance() -> Pushy {
        // Pushy instance singleton
        if pushy == nil {
            pushy = Pushy(UIApplication.shared)
        }
        
        return pushy!
    }

    // Runs after execution of AppDelegate.didFinishLaunchingWithOptions()
    override func pluginInitialize () {
        // Listen for startup notifications
        getPushyInstance().setNotificationHandler({ (data, completionHandler) in
            // Print notification payload data
            print("Received notification: \(data)")
            
            // Store for later
            self.startupNotification = data
            self.hasStartupNotification = true
            
            // You must call this completion handler when you finish processing
            // the notification (after fetching background data, if applicable)
            completionHandler(UIBackgroundFetchResult.newData)
        })
    }
    
    @objc(register:)
    func register(command: CDVInvokedUrlCommand) {
        // Register the device for push notifications
        getPushyInstance().register({ (error, deviceToken) in
            // Handle registration errors
            if error != nil {
                // Send error to Cordova app
                return self.commandDelegate!.send(
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: String(describing: error!)
                    ),
                    callbackId: command.callbackId
                )
            }
            
            // Send device token to Cordova app
            self.commandDelegate!.send(
                CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: deviceToken
                ),
                callbackId: command.callbackId
            )
        })
    }
    
    @objc(isRegistered:)
    func isRegistered(command: CDVInvokedUrlCommand) {
        // Check whether the device is registered
        let result = getPushyInstance().isRegistered()
        
        // Send result to Cordova app
        self.commandDelegate!.send(
            CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: result
            ),
            callbackId: command.callbackId
        )
    }
    
    @objc(setNotificationListener:)
    func setNotificationListener(command: CDVInvokedUrlCommand) {
        // Set notification handler
        getPushyInstance().setNotificationHandler({ (data, completionHandler) in
            // Print notification payload data
            print("Received notification: \(data)")
            
            // Prepare Cordova result object with notification payload dictionary
            let result = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: data
            )
            
            // Keep listener valid for multiple invocations
            result?.setKeepCallbackAs(true)
            
            // Send notification to Cordova app
            self.commandDelegate!.send(
                result,
                callbackId: command.callbackId
            )
            
            // Notification clicked?
            if data["_pushyNotificationClicked"] != nil {
                self.onNotificationClicked(data: data)
            }
            
            // Call the completion handler immediately on behalf of the app
            completionHandler(UIBackgroundFetchResult.newData)
        })
        
        // Check for startup notification if set
        if self.hasStartupNotification {
            // Execute notification handler (pass in startup notification payload)
            getPushyInstance().getNotificationHandler()?(self.startupNotification!, {(UIBackgroundFetchResult) in})
        }
    }
    
    @objc(setNotificationClickListener:)
    func setNotificationClickListener(command: CDVInvokedUrlCommand) {
        // Save callback for later
        self.notificationClickCallback = command
        
        // Check if startup notification was set (always clicked by the user)
        if self.hasStartupNotification {
            self.onNotificationClicked(data: self.startupNotification!)
        }
    }
    
    func onNotificationClicked(data: [AnyHashable : Any]) {
        // No callback defined?
        if self.notificationClickCallback == nil {
            return
        }
        
        // Prepare Cordova result object with notification payload dictionary
        let result = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: data
        )
        
        // Keep listener valid for multiple invocations
        result?.setKeepCallbackAs(true)
        
        // Send notification to Cordova app
        self.commandDelegate!.send(
            result,
            callbackId: self.notificationClickCallback!.callbackId
        )
    }
    
    @objc(subscribe:)
    func subscribe(command: CDVInvokedUrlCommand) {
        // Subscribe the device to a topic
        getPushyInstance().subscribe(topic: command.arguments[0] as! String, handler: { (error) in
            // Handle errors
            if error != nil {
                // Send error to Cordova app
                return self.commandDelegate!.send(
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: String(describing: error!)
                    ),
                    callbackId: command.callbackId
                )
            }
            
            // Success
            self.commandDelegate!.send(
                CDVPluginResult(
                    status: CDVCommandStatus_OK
                ),
                callbackId: command.callbackId
            )
        })
    }
    
    
    @objc(unsubscribe:)
    func unsubscribe(command: CDVInvokedUrlCommand) {
        // Unsubscribe the device from a topic
        getPushyInstance().unsubscribe(topic: command.arguments[0] as! String, handler: { (error) in
            // Handle errors
            if error != nil {
                // Send error to Cordova app
                return self.commandDelegate!.send(
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: String(describing: error!)
                    ),
                    callbackId: command.callbackId
                )
            }
            
            // Success
            self.commandDelegate!.send(
                CDVPluginResult(
                    status: CDVCommandStatus_OK
                ),
                callbackId: command.callbackId
            )
        })
    }

    @objc(setEnterpriseConfig:)
    func setEnterpriseConfig(command: CDVInvokedUrlCommand) {
        // Set Pushy Enterprise API endpoint
        getPushyInstance().setEnterpriseConfig(apiEndpoint: command.arguments[0] as! String)
        
        // Always success
        self.commandDelegate!.send(
            CDVPluginResult(
                status: CDVCommandStatus_OK
            ),
            callbackId: command.callbackId
        )
    }
}
