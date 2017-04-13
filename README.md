# Don't Stop The Party
By [wizages](https://twitter.com/Wizages "Wizage's twitter account") & [David Goldman](https://twitter.com/DavidJGoldman "David Golman's twitter account")

## How does this work?

### Step One - Prevent the app from killing itself

First off we must prevent the app from being terminated when SpringBoard is killed. When SpringBoard is lost all the apps want to do is shutdown. So we don't allow this to happen on the now playing app. We do this by preventing the `clientSystemApplicationTerminated:` from running. When we prevent the app from terminating itself we also setup a notification that we should receive later that will allow us to reconnect us to SpringBoard. More this will be explained in Step Five.

### Step Two - Prevent SpringBoard from killing the app

After SpringBoard recovers, SpringBoard wants a fresh start so it will call `FBApplicationProcess deleteAllJobs` which kills all remaining apps that are still left. How this does this is it calls upon the big almighty `launchd`. `launchd` controls all current running jobs including the app that you prevented its termination. So we need to prevent it from being killed at this step by just allowing all other apps to be terminated unless the bundle id of the now playing application is present in the name.

### Step Three - Reconnecting the app to backboardd

This step is very easy. We need to provide backboardd with a PID of the app that is still running. We run this before springboard is fully started so we can make sure that backboardd has the correct context. 

### Step Four - Providing Springboard with generic information about the app.

When SpringBoard is almost fully started we want to give SpringBoard some general information. We will tell SpringBoard that this app is launched and we are running so that SpringBoard doesn't attempt to launch a brand new app. The reason why we set this app up as in the foreground is to make sure that when we get the app started up we want to have a valid FBScene. Also we add the app back into the process list so that way SpringBoard can reference it.

### Step Five - Sending the notification

After we told SpringBoard the app is real and is still running, the app now has a limited amount of time to send a message using FrontBoard to provide that the app is truely alive! So we send the notification via SpringBoard and the now playing app receives the notification and sends a message using FrontBoard. This message has no content and has no real meaning to SpringBoard. It just makes SpringBoard happy.

### Step Six - Lets give our app some scenes

Now that SpringBoard believes we are real, we need to remind the app that we are still valid to show views. So we flash the app in the foreground and then throw it in the background where it belongs. This pretty much tells the app when we launch the app we want a valid FBScene and we want want it now! After that we put it where it should be which is in the background so we don't waste your battery. Now you have a fully reconnected app and you have officially survived the respring!

## Weird quirks and things we had to patch along the way

So if you notice we skipped over some things in the code and here is where talk about this fun stuff!

### BTServer - The bug that fooled us all

This bug was our biggest hold up during this entire development process. This bug had to do with us sending XPC message to BTServer and BTServer didn't think the app was still alive. So how we prevented this was preventing all XPC messages being sent to BTServer. (This is a total hack and should be taken with a grain of salt. I am salty about this bug still. Don't bug me about it.)

### App Switcher Bug - iOS 9 bug

This bug was just a matter of `launchd` not wanting the process to be deleted after it failed to delete the first time. We solved this by just remembering the last now playing pid and process name and then forcing that app to be deleted after it is told to shutdown

### Lockscreen not updating bug - We want ColorFlow 3

This bug had two parts, first we needed to send a notification saying that the nowplayinginfo changed so that the lockscreen would get the information. The second part was the fact that it didn't want to show the now playing screen. This was solved with some code that we wouldn't allow the lockscreen to find the view til it didn't equal null.

## Demo and Notes

[![Demo of our tweak](https://img.youtube.com/vi/CdpCcn4XR3c/0.jpg)](https://www.youtube.com/watch?v=CdpCcn4XR3c)

Please note that the Demo and process described above is a general overview of the full version. The lite version does most of the same things but only applies it to the Apple Music app.

## License

See License File
