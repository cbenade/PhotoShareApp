//
//  SocketIOManager.swift
//  PhotoShareApp
//
//  Created by Christian Benade on 2019-11-25.
//  Copyright © 2019 Christian Benade. All rights reserved.
//

import UIKit
import SocketIO

class SocketIOManager: NSObject {
    
    // Use singleton to access SocketIO Manager from any view controller
    static let shared = SocketIOManager()
    
    // Create socket variable
    var socket: SocketIOClient!
    
    // Create socket manager
    let manager = SocketManager(socketURL: URL(string: "https://photoshareserver.herokuapp.com/")!)
    
    override init() {
        super.init()
        UserDefaults.standard.set(nil, forKey: "groupName")
        socket = manager.defaultSocket
    }
    
    // Connects user to PhotoShareServer, emits message for user to join server side room corresponding to groupName if groupName != nil
    func connect() {
        socket.connect()
        if let room = UserDefaults.standard.string(forKey: "groupName") {
            socket.emit("join", "\(room)")
        }
    }
    
    // Disconnects user from PhotoShareServer, emits message for user to leave server side room corresponding to groupName if groupName != nil
    func disconnect() {
        if let room = UserDefaults.standard.string(forKey: "groupName") {
            socket.emit("leave", "\(room)")
        }
        socket.disconnect()
    }
    
    // After sucessful connection to PhotoShareServer, client device is set to "listen" for server messages with the following handles
    func listenForServer() {
        socket.on("aUserHasConnected") {(dataArray, socketAck) -> Void in
            print("a user connected")
        }
        socket.on("aUserHasDisconnected") {(dataArray, socketAck) -> Void in
            print("a user disconnected")
        }
        socket.on("imageUploaded") {(dataArray, socketAck) -> Void in
            print("SocketIOManager recieved server notification")
            // Post notification to view controllers
            NotificationCenter.default.post(name: NSNotification.Name("serverNotificationReceived"), object: nil)
        }
    }
    
    // Upon sucessful image uploads to AWS, device emits message to PhotoShareServer to notify other users in room of new available data
    func notifyPhotoUploaded() {
        if let room = UserDefaults.standard.string(forKey: "groupName") {
            socket.emit("uploadNotification", "\(room)")
        }
    }
}

