#define kBKSBackgroundModeUnboundedTaskCompletion @"unboundedTaskCompletion"
#define kBKSBackgroundModeContinuous              @"continuous"
#define kBKSBackgroundModeFetch                   @"fetch"
#define kBKSBackgroundModeRemoteNotification      @"remote-notification"
#define kBKSBackgroundModeExternalAccessory       @"external-accessory"
#define kBKSBackgroundModeVoIP                    @"voip"
#define kBKSBackgroundModeLocation                @"location"
#define kBKSBackgroundModeAudio                   @"audio"
#define kBKSBackgroundModeBluetoothCentral        @"bluetooth-central"
#define kBKSBackgroundModeBluetoothPeripheral     @"bluetooth-peripheral"

@interface FBSProcessHandle : NSObject
@property(nonatomic, copy) NSString *jobLabel;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, readonly, copy) NSString *bundleIdentifier;
@property(nonatomic, readonly) int pid;
@property(nonatomic) long long type;
@end

@interface FBProcessManager : NSObject
+ (id)sharedInstance;

- (id)applicationProcessForPID:(int)pid;
@end

@interface FBSSceneSettings : NSObject
@end

@interface SBLockScreenNowPlayingController
- (void)_updateNowPlayingPlugin;
@end

@interface SBLockScreenSettings
- (void)setShowNowPlaying:(BOOL)showNowPlaying;
@end

@interface FBSMutableSceneSettings : FBSSceneSettings
@property(nonatomic, getter=isBackgrounded) BOOL backgrounded;
@end

@interface FBScene : NSObject
@property(readonly, retain, nonatomic) FBSMutableSceneSettings *mutableSettings;
@property(readonly, retain, nonatomic) FBSSceneSettings *settings;
- (void)_applyMutableSettings:(id)arg1 withTransitionContext:(id)arg2 completion:(id)arg3;
@end

@interface SBApplication
- (NSString *)bundleIdentifier;
- (void)clearDeactivationSettings;
- (FBScene *)mainScene;
- (id)mainScreenContextHostManager;
- (id)mainSceneID;
- (void)activate;
- (void)setFlag:(long long)arg1 forActivationSetting:(unsigned int)arg2;
- (void)processDidLaunch:(id)arg1;
- (void)processWillLaunch:(id)arg1;
- (void)resumeForContentAvailable;
- (void)resumeToQuit;
- (void)_sendDidLaunchNotification:(BOOL)arg1;
- (void)notifyResumeActiveForReason:(long long)arg1;
- (void)setApplicationState:(unsigned int)applicationState;
@end
@interface SBApplicationController : NSObject
+ (id)sharedInstance;

- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;

@property(nonatomic, readonly) SBApplication *nowPlayingApplication;

- (BOOL)isPlaying;
- (BOOL)togglePlayPause;
@end

@interface SpringBoard : UIApplication
- (void)dnstp_fixUpNowPlayingForPID:(int)pid bundleID:(NSString *)bundleID;
- (void)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;

- (void)dnstp_updateNowPlayingWithMediaController:(SBMediaController *)mediaController;
@end

typedef NS_ENUM(NSUInteger, BKSProcessAssertionReason) {
	BKSProcessAssertionReasonNone = 0,
	BKSProcessAssertionReasonAudio = 1,
	BKSProcessAssertionReasonLocation = 2,
	BKSProcessAssertionReasonExternalAccessory = 3,
	BKSProcessAssertionReasonFinishTask = 4,
	BKSProcessAssertionReasonBluetooth = 5,
	BKSProcessAssertionReasonNetworkAuthentication = 6,
	BKSProcessAssertionReasonBackgroundUI = 7,
	BKSProcessAssertionReasonInterAppAudioStreaming = 8,
	BKSProcessAssertionReasonViewServices = 9,
	BKSProcessAssertionReasonNewsstandDownload = 10,
	BKSProcessAssertionReasonBackgroundDownload = 11,
	BKSProcessAssertionReasonVOiP = 12,
	BKSProcessAssertionReasonExtension = 13,
	BKSProcessAssertionReasonContinuityStreams = 14,
	// 15-9999 unknown
	BKSProcessAssertionReasonActivation = 10000,
	BKSProcessAssertionReasonSuspend = 10001,
	BKSProcessAssertionReasonTransientWakeup = 10002,
	BKSProcessAssertionReasonVOiP_PreiOS8 = 10003,
	BKSProcessAssertionReasonPeriodicTask_iOS8 = BKSProcessAssertionReasonVOiP_PreiOS8,
	BKSProcessAssertionReasonFinishTaskUnbounded = 10004,
	BKSProcessAssertionReasonContinuous = 10005,
	BKSProcessAssertionReasonBackgroundContentFetching = 10006,
	BKSProcessAssertionReasonNotificationAction = 10007,
	// 10008-49999 unknown
	BKSProcessAssertionReasonFinishTaskAfterBackgroundContentFetching = 50000,
	BKSProcessAssertionReasonFinishTaskAfterBackgroundDownload = 50001,
	BKSProcessAssertionReasonFinishTaskAfterPeriodicTask = 50002,
	BKSProcessAssertionReasonAFterNoficationAction = 50003,
	// 50004+ unknown
};

typedef NS_ENUM(NSUInteger, ProcessAssertionFlags) {
	BKSProcessAssertionFlagNone = 0,
	BKSProcessAssertionFlagPreventSuspend         = 1 << 0,
	BKSProcessAssertionFlagPreventThrottleDownCPU = 1 << 1,
	BKSProcessAssertionFlagAllowIdleSleep         = 1 << 2,
	BKSProcessAssertionFlagWantsForegroundResourcePriority  = 1 << 3
};

@interface BKSProcessAssertion : NSObject

- (instancetype)initWithPID:(NSInteger)pid flags:(NSUInteger)flags reason:(NSUInteger)reason name:(NSString *)name withHandler:(id)handler;

+ (NSString *)NameForReason:(NSUInteger)reason;

- (BOOL)valid;

@end


@interface SBLaunchAppListener 

- (id)initWithBundleIdentifier:(id)arg1 handlerBlock:(void (^)(void))arg2;


@end