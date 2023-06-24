# PhotoShareApp

## Description
PhotoShareApp is an easy to use service that allows users to view and share images in a specified photo feed of their choice. Users who are connected to the same feed will be able to view and download images sent by other users as well as be able post and upload to the group images of their own.

## How to Use
To use PhotoShareApp, all that is required of the user is to install the app onto their device. All associated dependencies for the app should be included automatically when cloning the PhotoShareApp GitHub repo and no further registration or steps are required by the user in the app. To join a room, simply type any code into the "Room ID" text field and press "Go to Feed". Uploading an image is similarly self-explanatory after navigating to the "Upload" view acessible from the top-right corner. PhotoShareApp will automatically connect the user to both AWS and PhotoShareServer and image data fetching should happen automatically in the background without user action necessary.

**Verify that PhotoShareServer is running before testing the app in order to get the best possible user experience. Scheduling a time-window in which the server should be running if possible would be best viable option.**

## Key Features
* PhotoShareApp uses the SocketIO library to connect users to PhotoShareServer via the WebSocket protocol. Because of this, users are able to receive real-time updates from the server as soon as new images are posted. User devices are set to notify the server whenever a new image has been sucessfully uploaded and server emits are sent to all other devices within the associated room name tag.
* Users can preview individual images seperately using a scrolling image view with the ability to select, upload, or download individual images chosen either from their own library or from images taken directly with their camera using the in-app camera feature.
* While PhotoShareServer is running on the [Heroku Cloud Application Platform](https://www.heroku.com/), users will receive banner alert notifications on their devices as soon as new data has been uploaded to AWS. The latest image data will begin to download automatically as long as their devices remain connected to PhotoShareServer. Images are available on all connected devices through the use of the [Amazon S3](https://aws.amazon.com/s3/) cloud platform.
* Retrieved images from visited feeds are stored locally in the application's temporary directory until the user specifically requests the app to save a given image to their devices personal photo library.
