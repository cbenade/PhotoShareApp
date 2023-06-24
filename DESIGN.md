# PhotoShareApp

## Tools
PhotoShareApp was created using the following tools:
* [Cocoa Pods](https://cocoapods.org/) - Dependency manager for Swift used to integrate [SocketIO](https://github.com/socketio/socket.io-client-swift) and [Amazon Web Services](https://aws.amazon.com/) into the project.
* [Heroku](https://www.heroku.com/) - Cloud application platform used to remotely host the SocketIO/Flask server
* [XCode](https://developer.apple.com/xcode/)/[Visual Studio Code](https://code.visualstudio.com/) - IDE/Text Editor used for writing and managing the client/server projects and code.
* [GitHub](https://github.com/) - Hosting service used for project Git version control.

## Code Details

### Classes
PhotoShareApp uses two custom singleton manager classes to access SocketIO & AWS features from any given view controller. SocketIO is used to connect/disconnect to the PhotoShareServer rooms aswell as emit/listen for server events which in turn trigger other commands such as to fetch AWS image data or post alert banner notifications.

### SceneDelegate/UserDefaults
Using the SceneDelegate class in conjunction with iOS's UserDefaults feature, PhotoShareApp is able to track the given room a current user is visiting in regardless of which view the user has loaded on their screen. Upon the app entering and leaving the device background/foreground, each user is automatically connected and disconnected from PhotoShareServer appropriately.

### Image Storage
To prevent the user from needing to download the same images repeatedly, room images are downloaded and stored in the application's "tmp" directory. This means that the images remain accessible to the user without persistently taking up considerable storage space on the users device. If a user would like to save a shared image from a feed to their personal device, they can do so in the "Upload" view meaning that only specifically requested images will become stored in the user's personal photo library.

### Real-time Updates
Because of SocketIO's use of the WebSocket protocol, connected users are able to recieve immediate updates regarding the uploaded status of other users images to their respective shared room. Upon recieving an alert from the server, user devices can automatically fetch the latest image data on the AWS S3 platform and alert the user with a notification set to display 1 second after receiving the server notice. The SocketIO library was chosen specifically for this project because of this feature and it's potential to deliver the best possible experience to the user.

### Image Views
Users browsing a given photo room/feed are able to choose whether they would like to view their respective room's images stitched together vertically or if they would instead prefer to view them individually. This provides the user with the options to either have a general overview of the photos are whether they would like to go navigate them individually and save some onto their device.

### Semaphores/Thread Blocking
While often times iOS's asynchronous abilities are a great thing, it was found during testing that some code blocks/sequences could execute in the wrong order and as a result images would often times not be displayed correctly. To remedy this issue, Semaphore's were used in some of AWS's upload/download functions in order to ensure that optional values would be not unwrapped too early and that empty arrays wouldn't be "loaded" into the UIScrollView when images were in fact available. One negative consequence of  implementing this blocking feature is that uploading/downloading very large image files periodically gives the app a brief appearance of being "frozen", as no corresponding loading wheel or progress bar has been implemented into the project.

### Image Hosting
AWS is used to host images remotely for all users and group/room name prefixes are used to categorize images accordingly, ensuring that only the correct images are downloaded onto each device when entering a given room/feed. Local images are stored in similarly named app folders in the "tmp" directory and it is from this directory that the local image views are loaded.
