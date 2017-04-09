#if __cplusplus
extern "C" {
#endif

  extern CFStringRef kMRMediaRemoteNowPlayingApplicationPIDUserInfoKey;
  extern CFStringRef kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey;

  extern CFStringRef kMRMediaRemoteNowPlayingInfoDidChangeNotification;
  extern CFStringRef kMRMediaRemoteNowPlayingPlaybackQueueDidChangeNotification;
  extern CFStringRef kMRMediaRemotePickableRoutesDidChangeNotification;
  extern CFStringRef kMRMediaRemoteNowPlayingApplicationDidChangeNotification;
  extern CFStringRef kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification;
  extern CFStringRef kMRMediaRemoteRouteStatusDidChangeNotification;

  #pragma mark - API

    typedef enum {
        /*
         * Use nil for userInfo.
         */
        kMRPlay = 0,
        kMRPause = 1,
        kMRTogglePlayPause = 2,
        kMRStop = 3,
        kMRNextTrack = 4,
        kMRPreviousTrack = 5,
        kMRToggleShuffle = 6,
        kMRToggleRepeat = 7,
        kMRStartForwardSeek = 8,
        kMREndForwardSeek = 9,
        kMRStartBackwardSeek = 10,
        kMREndBackwardSeek = 11,
        kMRGoBackFifteenSeconds = 12,
        kMRSkipFifteenSeconds = 13,

        /*
         * Use a NSDictionary for userInfo, which contains three keys:
         * kMRMediaRemoteOptionTrackID
         * kMRMediaRemoteOptionStationID
         * kMRMediaRemoteOptionStationHash
         */
        kMRLikeTrack = 0x6A,
        kMRBanTrack = 0x6B,
        kMRAddTrackToWishList = 0x6C,
        kMRRemoveTrackFromWishList = 0x6D
    } MRCommand;

    Boolean MRMediaRemoteSendCommand(MRCommand command, id userInfo);

#if __cplusplus
}
#endif
