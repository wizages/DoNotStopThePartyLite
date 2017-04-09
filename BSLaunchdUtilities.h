@interface BSLaunchdUtilities : NSObject
+ (NSArray<NSString *> *)allJobLabels;
+ (void)deleteAllJobsWithLabelPrefix:(NSString *)prefix;
+ (void)deleteJobWithLabel:(NSString *)label;
+ (int)pidForLabel:(NSString *)arg1;
@end
