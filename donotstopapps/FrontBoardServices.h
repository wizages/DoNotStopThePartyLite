@interface FBSWorkspaceClient : NSObject
- (void)dnstp_connect;
- (void)_queue_sendMessage:(NSInteger)msg withEvent:(id)event withResponseEvent:(id /* block */)arg3 ofType:(Class)type;
- (void)_sendMessage:(NSInteger)msg withEvent:(id)event;
@end
@interface FBSWorkspace : NSObject
- (FBSWorkspaceClient *)_client;
@end
@interface FBSWorkspaceConnectEvent : NSObject
@property(nonatomic, readonly, retain) id processHandle;
@end
