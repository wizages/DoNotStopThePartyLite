#import "BSLaunchdUtilities.h"
#import "MediaRemote.h"
#import "SpringBoard.h"

#import <notify.h>

#define kBKSBackgroundModeContinuous              @"continuous"

#define singleNowPlaying @"com.apple.Music"

static NSString * const kNowPlayingAppNotificationName = @"SBMediaNowPlayingAppChangedNotification";
static NSString * const kNowPlayingNotificationName = @"SBMediaNowPlayingChangedNotification";
static NSString * const kNowPlayingBundleIDKey = @"nowPlayingBundleID";
static NSString * const kNowPlayingPIDKey = @"nowPlayingPID";
static NSString * const kStatePlistPath = @"/User/Library/Preferences/com.jblounge.donotstop.plist";

static const unsigned kApplicationStateForegroundRunning = 4;

static NSString *currentNowPlayingBundleID = @"com.apple.Music";
static int currentNowPlayingPID = 0;
static BOOL currentNowPlayingValid = NO;

//Load the now current playing for respring
static void loadCurrentNowPlaying() {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kStatePlistPath];
    currentNowPlayingBundleID = [dict[kNowPlayingBundleIDKey] retain];
    currentNowPlayingPID = [dict[kNowPlayingPIDKey] intValue];
    currentNowPlayingValid = NO; // Invalid until verified in -|_serviceClientAddedWithProcessHandle|
}

//Update the dictionary with the now playing tweak if ness
static void updateAndSaveCurrentNowPlaying(NSString *bundleID, int pid) {
    if ([currentNowPlayingBundleID isEqualToString:bundleID] && currentNowPlayingPID == pid) {
        return;
    }
    if ([bundleID isEqualToString:singleNowPlaying] || bundleID == nil || pid == 0){
        [currentNowPlayingBundleID release];
        currentNowPlayingBundleID = [bundleID copy];
        currentNowPlayingPID = pid;
        currentNowPlayingValid = (bundleID && pid > 0);
        NSDictionary *dict = !currentNowPlayingValid ? @{} : @{
                kNowPlayingBundleIDKey: bundleID,
                kNowPlayingPIDKey: @(pid)
            };
        [dict writeToFile:kStatePlistPath atomically:YES];
    }
}

//Send notifications for other tweaks to notice we are rocking and a rolling.
static void postMediaRemoteNotification() {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:(NSString *)kMRMediaRemoteNowPlayingApplicationDidChangeNotification
                                                object:nil];
    [center postNotificationName:(NSString *)kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification
                                                object:nil
                                            userInfo:@{(NSString *)kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey: @(YES)}];
}

// Called by +|FBApplicationProcess deleteAllJobs|. Maybe hook that instead?
//Prevents launchd from shutting the apps down.
%hook BSLaunchdUtilities
+ (void)deleteAllJobsWithLabelPrefix:(NSString *)prefix {
    if (!currentNowPlayingBundleID) {
        %orig;
        return;
    }

    NSArray<NSString *> *allJobLabels = [self allJobLabels];
    for (NSString *job in allJobLabels) {
        if ([job hasPrefix:prefix]) {
            if (![job containsString:currentNowPlayingBundleID]) {
                [self deleteJobWithLabel:job];
            } else {
                // Make sure it's the right PID.
                int pid = [self pidForLabel:job];
                if (pid != currentNowPlayingPID) {
                    [self deleteJobWithLabel:job];
                }
            }
        }
    }
}
%end

// Need to notify the app that we started back up.
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    if (currentNowPlayingValid) {
        [[%c(BKSProcessAssertion) alloc] initWithPID:currentNowPlayingPID flags:BKSProcessAssertionFlagPreventSuspend | BKSProcessAssertionFlagPreventThrottleDownCPU | BKSProcessAssertionFlagWantsForegroundResourcePriority reason:BKSProcessAssertionReasonContinuous name:kBKSBackgroundModeContinuous withHandler:nil];
    }

    %orig;

    if (currentNowPlayingValid) {
        [self dnstp_fixUpNowPlayingForPID:currentNowPlayingPID bundleID:singleNowPlaying];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                                                                     selector:@selector(dnstp_nowPlayingChanged:)
                                                                                             name:kNowPlayingNotificationName
                                                                                         object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                                                     selector:@selector(dnstp_nowPlayingAppChanged:)
                                                                                             name:kNowPlayingAppNotificationName
                                                                                         object:nil];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}
//Calls update function
%new
- (void)dnstp_nowPlayingAppChanged:(NSNotification *)notification {
    SBMediaController *mediaController = notification.object;
    [self dnstp_updateNowPlayingWithMediaController:mediaController];
}
//Calls update function
%new
- (void)dnstp_nowPlayingChanged:(NSNotification *)notification {
    SBMediaController *mediaController = notification.object;
    [self dnstp_updateNowPlayingWithMediaController:mediaController];
}
//Updates the now playing application (nil if nothing is playing)
%new
- (void)dnstp_updateNowPlayingWithMediaController:(SBMediaController *)mediaController {
    SBApplication *nowPlayingApplication = mediaController.nowPlayingApplication;
    NSString *bundleIdentifier = [nowPlayingApplication bundleIdentifier];
    int pid = MSHookIvar<int>(mediaController, "_lastNowPlayingAppPID");
    BOOL playing = [mediaController isPlaying];

    if (!playing || pid <= 0 || !bundleIdentifier || ![bundleIdentifier isEqualToString:singleNowPlaying]) {
        updateAndSaveCurrentNowPlaying(nil, 0);
    } else {
        updateAndSaveCurrentNowPlaying(bundleIdentifier, pid);
    }
}
//This reattaches the process to Springboard
%new
- (void)dnstp_fixUpNowPlayingForPID:(int)pid bundleID:(NSString *)bundleID {
    if ([bundleID isEqualToString:singleNowPlaying]){
        FBProcessManager *processManager = [%c(FBProcessManager) sharedInstance];
        id process = [processManager applicationProcessForPID:pid];
        if (!process) {
            return;
        }

        SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleID];
        [application processWillLaunch:process];
        [application processDidLaunch:process];
        [application setApplicationState:kApplicationStateForegroundRunning];

        [(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:bundleID suspended:YES];

        dispatch_time_t timedis = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);

        dispatch_after(timedis, dispatch_get_main_queue(), ^(void){

            SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleID];
             FBScene *scene = [application mainScene];
             if (!scene || !scene.settings || !scene.mutableSettings) {
                 return;
             }

             FBSMutableSceneSettings *sceneSettings = scene.mutableSettings;
             sceneSettings.backgrounded = NO;
             [scene _applyMutableSettings:sceneSettings withTransitionContext:nil completion:nil];
             FBSMutableSceneSettings *sceneSettings2 = scene.mutableSettings;
             sceneSettings2.backgrounded = YES;
             [scene _applyMutableSettings:sceneSettings2 withTransitionContext:nil completion:nil];
        });


        notify_post("do-not-stop-the-party!");

        postMediaRemoteNotification();

    }
    
}
%end

// Fix for artwork not showing up immediately after a respring.
%hook MPULockScreenMediaControlsViewController
- (void)nowPlayingController:(id)npc nowPlayingInfoDidChange:(NSDictionary *)info {
    id view = MSHookIvar<id>(self, "_mediaControlsView");

    if (view) {
        %orig;
    }
}
%end

%group iOS10
%hook FBProcessManager
//Adds the process back into the process list for iOS 10
- (id)_serviceClientAddedWithProcessHandle:(FBSProcessHandle *)processHandle {
    if (!currentNowPlayingBundleID) {
        return %orig;
    }

    NSString *bundleIdentifier = processHandle.bundleIdentifier;
    int pid = processHandle.pid;
    long long type = processHandle.type;

    // Type 2 seems to make the added process an FBApplicationProcess, not an FBProcess.
    if ([bundleIdentifier isEqualToString:singleNowPlaying] && pid == currentNowPlayingPID) {
        processHandle.type = 2;
        id result = %orig;
        processHandle.type = type;

        currentNowPlayingValid = YES;
        return result;
    } else {
        return %orig;
    }
}
%end
%end

%group iOS9
//Adds the process back into the process list for iOS 9
%hook FBProcessManager
- (id)_serviceClientAddedWithPID:(int)pid isUIApp:(BOOL)isUIApp isExtension:(BOOL)isExte bundleID:(NSString *)bundleID {
    if (!currentNowPlayingBundleID) {
        return %orig;
    }

    // Type 2 seems to make the added process an FBApplicationProcess, not an FBProcess.
    if ([bundleID isEqualToString:singleNowPlaying] && pid == currentNowPlayingPID) {
        currentNowPlayingValid = YES;
    }

    return %orig;
}
%end

//Fixes an issue where the switcher would not remove the process from the Launchd
//This is a hack.... A better solution should be found.
%hook SBMainSwitcherViewController
-(void)_quitAppRepresentedByDisplayItem:(id)arg1 forReason:(long long)arg2 {
    %orig;
    if ([[arg1 valueForKey:@"_displayIdentifier"] isEqualToString:singleNowPlaying]){
        NSArray<NSString *> *allJobLabels = [%c(BSLaunchdUtilities) allJobLabels];
        for (NSString *job in allJobLabels) {
            if ([job containsString:singleNowPlaying]) {
                [%c(BSLaunchdUtilities) deleteJobWithLabel:job];
            }
        }
    }
}
%end
%end

%ctor {
    %init;

    Class FBProcessManager = %c(FBProcessManager);
    if ([FBProcessManager instancesRespondToSelector:@selector(_serviceClientAddedWithProcessHandle:)]) {
        %init(iOS10);
    } else if ([FBProcessManager instancesRespondToSelector:@selector(_serviceClientAddedWithPID:isUIApp:isExtension:bundleID:)]) {
        %init(iOS9);
    }

    loadCurrentNowPlaying();
}
