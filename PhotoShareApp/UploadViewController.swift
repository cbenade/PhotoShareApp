//
//  UploadViewController.swift
//  PhotoShareApp
//
//  Created by Christian Benade on 2019-11-28.
//  Copyright © 2019 Christian Benade. All rights reserved.
//

import UIKit


class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var groupName: String!
    var nextImageNumber: Int!
    var imageNSURL: NSURL!
    var imageName: String!
    var downloadedImageList: [String] = []
    var downloadedUIImageList: [UIImage] = []
    var imageFeedIndex: Int = 0
    
    @IBOutlet var uploadImageBarButtonItem: UIBarButtonItem!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var saveImageButton: UIButton!
    @IBOutlet var viewFeedButton: UIButton!
    @IBOutlet var feedPhotosLeftButton: UIButton!
    @IBOutlet var feedPhotosRightButton: UIButton!
    @IBOutlet var viewPhotoLibraryBarButtonItem: UIBarButtonItem!
    @IBOutlet var useCameraBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        // Init notification observer, remove first observer to ensure notifications are not duplicated
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name("serverNotificationReceived"),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(serverNotificationResponse),
                                               name: NSNotification.Name("serverNotificationReceived"),
                                               object: nil)
        
        // Initialize downloadedImageList and downloadedUIImageList for feed image scrolling
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
        for keyName in downloadedImageList {
            let imagePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(keyName).relativeString.replacingOccurrences(
                of: "file://",
                with: "",
                options: NSString.CompareOptions.literal,
                range:nil)
            if let keyNameUIImage = UIImage(contentsOfFile: imagePath) {
                downloadedUIImageList.append(keyNameUIImage)
            }
        }
    }
    
    // Increment nextImageNumber after recieving server notification, used so next uploaded image number is incremented properly
    @objc private func serverNotificationResponse() {
        print("UploadViewController was alerted about serverNotificationReceived")
        nextImageNumber += 1
    }
    
    // Set UIImageView image to image chosen from library or taken with camera
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.navigationController?.dismiss(animated: true, completion: nil)
        // Set UIImageView to chosen image
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            // If image chosen from device, save NSURL for AWS upload, otherwise generate random image name and save NSURL another way
            if let imageNSURL = info[UIImagePickerController.InfoKey.imageURL] as? NSURL {
                self.imageNSURL = imageNSURL
            } else {
                // If photo taken with camera, save JPEG copy to tmp directory prior to upload
                let jpgImageData = image.jpegData(compressionQuality: 1.0)
                let characterPool = "0123456789ABCDEF"
                let randomizedString =
                    String((0..<8).map{ _ in characterPool.randomElement()! }) + "-" +
                    String((0..<4).map{ _ in characterPool.randomElement()! }) + "-" +
                    String((0..<4).map{ _ in characterPool.randomElement()! }) + "-" +
                    String((0..<4).map{ _ in characterPool.randomElement()! }) + "-" +
                    String((0..<12).map{ _ in characterPool.randomElement()! })
                let fileWritePath = URL(
                    fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(randomizedString + ".jpeg")
                do {
                    try jpgImageData!.write(to: fileWritePath)
                } catch let error as NSError {
                    print("Error writing image to directory: \(error.localizedDescription)")
                    return
                }
                self.imageNSURL = fileWritePath as NSURL
            }
            // Append formatted nextImageNumber to imageName to keep sorted UIImage array in order
            self.imageName = String(format: "%05d-", nextImageNumber) +
                self.imageNSURL.relativeString.replacingOccurrences(
                    of: "file://\(NSTemporaryDirectory())",
                    with: "",
                    options: NSString.CompareOptions.literal,
                    range:nil)
        }
    }
    
    // Picker function used to choose UIImageView image from photo library
    @IBAction func chooseLibraryPhoto(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            self.navigationController?.present(picker, animated: true, completion: nil)
        }
    }
    
    // Save image in UIImageView to device photo library
    @IBAction func saveImageToPhotoLibrary() {
        if imageView.image == nil {
            let ac = UIAlertController(title: "Not Saved!",
                                       message: "No image selected to save.",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            present(ac, animated: true)
            return
        } else {
            UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
            let ac = UIAlertController(title: "Saved!", message: "Image saved to Photo Library", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            present(ac, animated: true)
        }
        
    }
    
    // Set UIImageView image to photo taken with device camera
    @IBAction func takeCameraPhoto(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            self.navigationController?.present(picker, animated: true, completion: nil)
        }
    }
    
    // Call AWSManager to upload UIImageView image to AWS s3bucketname/groupName
    @IBAction func uploadImageToAWS() {
        // Display alert if UIImageView is empty (no image chosen)
        if imageView.image == nil {
            let ac = UIAlertController(title: "Not Uploaded!",
                                       message: "No image selected for upload",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            present(ac, animated: true)
        }
        // Display alert if UIImageView image is already present in the downloadedUIImageList (no image chosen)
        else if downloadedUIImageList.contains(imageView.image!) {
            let ac = UIAlertController(title: "Not Uploaded!",
                                       message: "This image has already been added to the feed",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            present(ac, animated: true)
        }
        // Proceed with upload if imageNSURL and imageName variables are populated (!= nil)
        else if imageNSURL != nil && imageName != nil {
            if AWSManager.shared.uploadImage(keyName: groupName + "/" + imageName, uploadFileNSURL: imageNSURL) != nil {
                print("Upload successful.")
                // Upon successful upload, emit message to PhotoAppServer that an image has been sucessfully added to the group
                SocketIOManager.shared.notifyPhotoUploaded()
                let ac = UIAlertController(title: "Uploaded!",
                                           message: "Image uploaded to AWS s3BucketName/\(groupName!)/ ",
                                           preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
                present(ac, animated: true)
            } else {
                print("Upload unsuccessful.")
                let ac = UIAlertController(title: "Not Uploaded!",
                                           message: "Image not uploaded to AWS, server responded with an error",
                                           preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
                present(ac, animated: true)
            }
        }
    }
    
    // Set UIImageView to individual image from the groupName feed
    @IBAction func viewFeedPhotos() {
        if !downloadedImageList.isEmpty {
            imageView.image = downloadedUIImageList[imageFeedIndex]
        }
    }
    
    // Set UIImageView to next image in the groupName feed
    @IBAction func feedPhotosLeft() {
        if !downloadedImageList.isEmpty {
            imageFeedIndex -= 1
            if imageFeedIndex < 0 {
                imageFeedIndex = downloadedUIImageList.count - 1
            }
            imageView.image = downloadedUIImageList[imageFeedIndex]
        }
    }
    
    // Set UIImageView to previous image in the groupName feed
    @IBAction func feedPhotosRight() {
        if !downloadedImageList.isEmpty {
            imageFeedIndex += 1
            if imageFeedIndex == downloadedUIImageList.count {
                imageFeedIndex = 0
            }
            imageView.image = downloadedUIImageList[imageFeedIndex]
        }
    }
}
