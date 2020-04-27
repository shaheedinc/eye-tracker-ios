# Eye-Tracker-iOS
An iOS app that can detect if the user is looking on the screen or not.

## Installation

Clone this project:

```
git clone https://github.com/shaheedinc/eye-tracker-ios.git
```

Install the dependencies:

```
cd eye-tracker-ios
cd iOS App
pod install
```

> This will install all the required dependencies hosted in POD

## Configure Firebase

1. Create a firebase app using the Firebase console.
2. Add an iOS app on the Firebase console.
3. Copy and paste the GoogleService-Info.plist file on your iOS Application's root directory.

Run the App:

```
Open Eyes Tracking.xcworkspace using XCode
Use the play button on XCode
```

# Eye-Tracker-Data-Parser
A Java application that can parse the data from firebase and give you a csv file of the session records

## Installation

Install the dependencies:

This application requires you to have Maven installed on your command line. Here is how to install it if you do not have it already: https://maven.apache.org/install.html

Once you have Maven installed run the following commands to install the dependecies and compile the project.

```
cd eye-tracker-ios
cd Parser (JAVA)
mvn clean
mvn build
```

> This will install all the required dependencies hosted in maven repositories.

## Configure Firebase Admin SDK

1. Log into the same firebase account.
2. In the Firebase console, open Settings > Service Accounts.
3. Click Generate New Private Key, then confirm by clicking Generate Key.
4. Copy and paste the JSON file containing the key to the root of the Java application.
5. Update the name of the file on Main.java line number 34.
6. Update the database url on Main.java line number 37.

Run the App:

```
Open the file using IntelliJ IDEA and run the Main.java file.
```

## How it works

1. The mobile app asks for a participant id when launched. This id is used to create a Firebase database object. This id is later used to identify different participants. 
2. After the database object is created, the app goes through a training process to accurately determine the boundaries of the screen. In this process, 8 separate red dots are shown in 8 edges of the screen, and the eye position is recorded. These records are later used to adjust the boundaries of the screen.
3. When the training is completed, the app loads Google's default search page using the internal WebKit library and starts to record all the activities on the database.
4. The app saves all the latest activities on the database as soon as the app enters background mode. So to make sure all the activities are saved, we need to shift the app to the background.
