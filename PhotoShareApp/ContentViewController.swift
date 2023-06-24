//
//  ContentViewController.swift
//  PhotoShareApp
//
//  Created by Christian Benade on 2019-11-28.
//  Copyright © 2019 Christian Benade. All rights reserved.
//

import AWSS3
import SocketIO
import UserNotifications
import UIKit


class ContentViewController: UIViewController, UIScrollViewDelegate, UNUserNotificationCenterDelegate {

    var groupName: String!
    var s3ImageList: [String] = []
    var downloadedImageList: [String] = []
    var keyNameUIImage: UIImage!
    var scrollPosition: CGFloat = 0
    
    @IBOutlet var imageScrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\(groupName!.uppercased()) Feed"
        
        // Create directory in "tmp" to store AWS images
        createDownloadImageDirectory(groupName: groupName)
        
        // Reset Scroll View height to zero prior to stitching photos vertically
        imageScrollView.contentSize.height = 0
        
        // Reconnect to server joining 'groupName' room for notifications/live updates
        SocketIOManager.shared.disconnect()
        UserDefaults.standard.set(groupName, forKey: "groupName")
        SocketIOManager.shared.connect()
        
        // Init notification observer and set delegate, remove first observer to ensure notifications are not duplicated
        UNUserNotificationCenter.current().delegate = self
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name("serverNotificationReceived"),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(serverNotificationResponse),
                                               name: NSNotification.Name("serverNotificationReceived"),
                                               object: nil)
        
        // Initialization for scrollview, stitches each image in tmp/groupName to the UIScrollView
        updateDownloadedImageList()
        for keyName in downloadedImageList {
            keyNameUIImage = returnUIImage(keyName: keyName)
            if keyNameUIImage != nil {
                renderScrollView(addedFrame: keyNameUIImage!)
            }
        }
        // After initializig images already downloaded, fetch any not-downloaded image from AWS and append to bottom of UIScrollView
        getMissingImages()
    }
    
    // Checks for new images when entering view
    override func viewDidAppear(_ animated: Bool) {
        getMissingImages()
    }
    
    // Gets missing images after recieving server notification, request banner notification
    @objc private func serverNotificationResponse() {
        print("ContentViewController was alerted about serverNotificationReceived!")
        getMissingImages()
        // If authorized, create a banner notification set to trigger in 1 second
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            if settings.alertSetting == .enabled {
                // Schedule an alert-only notification.
                let content = UNMutableNotificationContent()
                content.title = "New image downloaded!"
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
                let request = UNNotificationRequest(identifier: "ImageUploadNotification",
                                                    content: content,
                                                    trigger: trigger)
                let center = UNUserNotificationCenter.current()
                center.add(request) { (error) in
                   if error != nil {
                      print("Error: \(error!.localizedDescription)")
                   }
                }
            }
        }
    }
    
    // Protocol function for UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Test: \(response.notification.request.identifier)")
        completionHandler()
    }
    
    // Display upload notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // Create directory to store picture files in if directory doesn't already exist
    func createDownloadImageDirectory(groupName: String) {
        let downloadFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(groupName)
        do {
            try FileManager.default.createDirectory(atPath: downloadFilePath!.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
    }
    
    // Download images on AWS s3BucketName/groupName/ missing from downloaded image directory
    func fetchAndRenderMissingImages() {
        // Semaphore used to block function from terminating until images have been downloaded and appended to UIScrollView
        var semaphore = DispatchSemaphore(value: 0)
        var downloadFinished: Bool?
        for keyName in s3ImageList {
            if !downloadedImageList.contains(keyName) {
                semaphore = DispatchSemaphore(value: 0)
                downloadFinished = AWSManager.shared.downloadImage(keyName: keyName)
                if downloadFinished! {
                    keyNameUIImage = returnUIImage(keyName: keyName)
                    if keyNameUIImage != nil {
                        renderScrollView(addedFrame: keyNameUIImage!)
                    }
                    semaphore.signal()
                } else {
                    semaphore.signal()
                }
            semaphore.wait()
            }
        }
    }
    
    // Fetches missing images from AWS and updates imageScrollView
    func getMissingImages() {
        // Get list of images hosted on AWS/groupName
        s3ImageList = AWSManager.shared.listImagesInGroup(groupName: groupName)
        
        // Update list of images downloaded in tmp directory
        updateDownloadedImageList()
        
        // Return if no images found on AWS
        if s3ImageList.isEmpty {
            return
        }
        
        // Download images missing from tmp/groupName and append to UIScrollView
        fetchAndRenderMissingImages()
    }
    
    // Save scroll position, add frame to scroll view with scaled dimensions, set scroll position back to saved value
    func renderScrollView(addedFrame: UIImage) {
        scrollPosition = imageScrollView.contentOffset.y
        let imageView = UIImageView()
        imageView.image = addedFrame
        let yPosition = imageScrollView.contentSize.height
        let width = view.bounds.width
        let height = (imageView.image!.size.height / imageView.image!.size.width) * width
        imageView.frame = CGRect(x: 0, y: yPosition, width: width, height: height)
        imageScrollView.contentSize.height += (imageView.image!.size.height / imageView.image!.size.width) * width
        imageScrollView.addSubview(imageView)
        imageScrollView.delegate = self
        imageScrollView.contentOffset.y = scrollPosition
    }
    
    // Returns UIImage for given image keyName
    func returnUIImage(keyName: String) -> UIImage? {
        let imagePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(keyName).relativeString.replacingOccurrences(
            of: "file://",
            with: "",
            options: NSString.CompareOptions.literal,
            range:nil)
        if UIImage(contentsOfFile: imagePath) != nil {
            return UIImage(contentsOfFile: imagePath)!
        }
        return nil
    }
    
    // Update's list of current files in groupName's downloaded image directory
    func updateDownloadedImageList() {
        do {
            let rawDownloadedImageList = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory() + "/" + self.groupName)
            for imageName in rawDownloadedImageList {
                if imageName != ".DS_Store" && !downloadedImageList.contains(groupName + "/" + imageName) {
                    downloadedImageList.append(groupName + "/" + imageName)
                }
            }
            downloadedImageList.sort()
        } catch let error {
            print("Error: \(error)")
        }
    }
    
    // Segue view to UploadViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UploadPhotoSegue",
            let destination = segue.destination as? UploadViewController {
            // Pass groupName and nextImageNumber variable to next view controller
            destination.groupName = self.groupName
            destination.nextImageNumber = self.s3ImageList.count
        }
    }
}
