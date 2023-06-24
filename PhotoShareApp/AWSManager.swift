//
//  AWSManager.swift
//  PhotoShareApp
//
//  Created by Christian Benade on 2019-11-27.
//  Copyright © 2019 Christian Benade. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognito
import AWSS3


class AWSManager {
    
    // Use singleton to access AWS Manager from any view controller
    static let shared = AWSManager()
    
    // Configure AWS objects prior to data transfer operations
    func configureAWSObjects() {
        
        // Create a credential provider object
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: .USWest2,
            identityPoolId: "us-west-2:5371e20e-f6cf-4c7b-9f46-f75c738cb0a6")
        
        // Setup a service configuration object
        let configuration = AWSServiceConfiguration(
            region: AWSRegionType.USWest2,
            credentialsProvider: credentialsProvider)
        AWSServiceManager.default()?.defaultServiceConfiguration = configuration
    }
    
    // Download image with 'fileName' from AWS to app temp directory: returns fileName if successful, nil if not
    func downloadImage(keyName: String) -> Bool? {
        
        // Semaphore used to block function from returning until image is fully completed downloading
        let semaphore = DispatchSemaphore(value: 0)
        
        var downloadSuccessful = false
        let s3BucketName = "photosharebucketcs50"
        let downloadFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(keyName)
            
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                NSLog("Downloading...")
            })
        }

        let completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { (task, URL, data, error) -> Void in DispatchQueue.main.async(execute: {
                if let error = error {
                    NSLog("Failed with error: \(error)")
                } else {
                    NSLog("Success.")
                }
            })
            semaphore.signal()
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.download(
            to: downloadFileURL!,
            bucket: s3BucketName,
            key: keyName,
            expression: expression,
            completionHandler: completionHandler).continueWith {
                (task) -> AnyObject? in
                    if let error = task.error {
                        print("Error: \(error.localizedDescription)")
                    }
                    if var _ = task.result {
                        downloadSuccessful = true
                    }
                    return nil;
        }
        
        // Return true if download is sucessful
        semaphore.wait()
        if downloadSuccessful == true {
            return true
        } else {
            return nil
        }
    }
    
    // Get list of images in s3BucketName/groupName/
    func listImagesInGroup(groupName: String) -> [String] {
        
        // Semaphore used to block function from returning until s3ImageList is sucessfuly retrieved from AWS
        let semaphore = DispatchSemaphore(value: 0)
        
        var fileList: [String] = []
        let s3 = AWSS3.default()
        
        if let listObjectsV2Request = AWSS3ListObjectsV2Request() {
            listObjectsV2Request.bucket = "photosharebucketcs50"
            listObjectsV2Request.prefix = groupName + "/"
            s3.listObjectsV2(listObjectsV2Request).continueWith {
                (task) -> AnyObject? in
                    if let error = task.error {
                       print("Error: \(error.localizedDescription)")
                    }
                    if let result = task.result {
                        if let contents = result.contents {
                            for picture in contents {
                                if picture.key! != "\(groupName)/" {
                                    fileList.append(picture.key!)
                                }
                            }
                        }
                    }
                    semaphore.signal()
                    return nil;
            }
        }

        // Return list
        semaphore.wait()
        return fileList
    }
    
    
    // Upload user chosen image to AWS from photos: returns fileName if successful, nil if not
    func uploadImage(keyName: String, uploadFileNSURL: NSURL) -> Bool? {

        // Semaphore used to block function from returning until image is fully completed uploaded
        let semaphore = DispatchSemaphore(value: 0)
        
        var uploadSuccessful = false
        let s3BucketName = "photosharebucketcs50"
        let contentType = "image/" + uploadFileNSURL.pathExtension!
                
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                NSLog("Uploading...")
            })
        }

        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in DispatchQueue.main.async(execute: {
                if let error = error {
                    NSLog("Failed with error: \(error)")
                } else {
                    NSLog("Success.")
                }
            })
            semaphore.signal()
        }

        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadFile(
            uploadFileNSURL as URL,
            bucket: s3BucketName,
            key: keyName,
            contentType: contentType,
            expression: expression,
            completionHandler: completionHandler).continueWith {
                (task) -> AnyObject? in
                    if let error = task.error {
                      print("Error: \(error.localizedDescription)")
                    }
                    if let _ = task.result {
                      uploadSuccessful = true
                    }
                    return nil;
           }

        // Return true if upload is sucessful
        semaphore.wait()
        if uploadSuccessful == true {
            return true
        } else {
            return nil
        }
    }
}
