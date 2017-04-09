#import "FrontBoardServices.h"

#import <notify.h>
#import "../MediaRemote.h"

#ifndef kCFCoreFoundationVersionNumber_iOS_10
#define kCFCoreFoundationVersionNumber_iOS_10 1348.00
#endif

static NSString * const kNowPlayingPIDKey = @"nowPlayingPID";
static NSString * const kStatePlistPath = @"/User/Library/Preferences/com.jblounge.donotstop.plist";
static NSString * const kNowPlayingBundleIDKey = @"nowPlayingBundleID";

static char * (*xpc_copy_description)(void *object);
static int64_t (*xpc_dictionary_get_int64)(void *xdict, const char *key);

static int notifyToken = 0;
static BOOL notifyTokenRegistered = NO;

//Get the current plying PID
static int getNowPlayingPID() {
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kStatePlistPath];
  return [dict[kNowPlayingPIDKey] intValue];
}

//Get the current plying Bundle ID
static NSString* getNowPlayingBundleID(){
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kStatePlistPath];
  return dict[kNowPlayingBundleIDKey];
}

%hook FBSWorkspace

// Prevent shutting the app down when SpringBoard terminates.
- (void)clientSystemApplicationTerminated:(id)arg1 {
  if ([NSProcessInfo processInfo].processIdentifier != getNowPlayingPID() || ![getNowPlayingBundleID() isEqualToString:[[NSBundle mainBundle] bundleIdentifier]]) {
    %orig;
    return;
  }
  //Keeps some video players from stoping
  dispatch_time_t timedis = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);

  dispatch_after(timedis, dispatch_get_main_queue(), ^(void){
    MRMediaRemoteSendCommand(kMRPlay, nil);
  });
  if (!notifyTokenRegistered) {
    id client = [self _client];
    notifyTokenRegistered = NOTIFY_STATUS_OK == notify_register_dispatch("do-not-stop-the-party!", &notifyToken, dispatch_get_main_queue(), ^(int token) {
        [client dnstp_connect];

        if (notifyTokenRegistered) {
          notify_cancel(notifyToken);
          notifyTokenRegistered = NO;
        }
    });
  }
}
- (void)dealloc {
  if (notifyTokenRegistered) {
    notify_cancel(notifyToken);
    notifyTokenRegistered = NO;
  }
  %orig;
}
%end
%hook FBSWorkspaceClient
// We need to redo our handshake with SpringBoard once we get disconnected. However, it appears that
// trying to do this in the background will give us a crash with 0xdead10cc.
%new
- (void)dnstp_connect {
    [self _sendMessage:0 withEvent:nil];
}
%end

//Below is our fix for iOS 10 BTServer crashes. This is such a hack
static void (*orig_xpc_connection_send_message)(void *, void *);

static void new_xpc_connection_send_message(void *connection, void *message) {

  NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

  if ([getNowPlayingBundleID() isEqualToString:bundleIdentifier]){
    int64_t number = xpc_dictionary_get_int64(message, "kCBMsgId");
      if (number == 36){
        HBLogDebug(@"Prevented open");
      } else if (number == 37){
        HBLogDebug(@"prevented close");
      } else {
        orig_xpc_connection_send_message(connection, message);
      }
  } else {
    orig_xpc_connection_send_message(connection, message);
  }
}


%ctor {
  %init;
  if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10){
    void *handle = dlopen(NULL, RTLD_NOW);

    xpc_copy_description = (char * (*)(void *)) dlsym(handle, "xpc_copy_description");
    xpc_dictionary_get_int64 = (int64_t (*)(void *, const char *)) dlsym(handle, "xpc_dictionary_get_int64");

    void *xpc_connection_send_message = dlsym(handle, "xpc_connection_send_message");
    MSHookFunction(xpc_connection_send_message, (void *)&new_xpc_connection_send_message, (void **)&orig_xpc_connection_send_message);

    dlclose(handle);
  }
}