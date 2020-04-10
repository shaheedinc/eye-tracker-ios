# Eye-Tracker-IOS
An IOS app that can detect if the user is looking on the screen or not.

## Installation

Clone this project:

```
git clone https://github.com/shaheedinc/eye-tracker-ios.git
```

Install the dependencies:

```
cd eye-tracker-ios
cd IOS App
pod install
```

> This will install all the required dependencies hosted in POD

## Configure Firebase

1. Create a firebase app using the firebase console.
2. Add an IOS app on the firebase console.
3. Copy and paste the GoogleService-Info.plist file on your IOS Application's root directory.

Run the App:

```
Open Eyes Tracking.xcworkspace using XCode
Use the play button on XCode
```

# Eye-Tracker-Data-Parser
A java application that can parse the data from firebase and give you a csv file of the session records

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
4. Copy and paste the JSON file containing the key to the root of the JAVA application.
5. Update the name of the file on Main.java line number 34.
6. Update the database url on Main.java line number 37.

Run the App:

```
Open the file using Intellij Idea and run the Main.java file.
```
