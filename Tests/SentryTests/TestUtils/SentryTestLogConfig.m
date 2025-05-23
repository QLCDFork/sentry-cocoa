#import "SentryLog.h"
#import "SentrySwift.h"
#import <Foundation/Foundation.h>

/**
 * Confgures a the sentry log output for testing when this class is loaded.
 */
@interface SentryTestLogConfig : NSObject

+ (void)setDefaultTestLogging;

@end

@implementation SentryTestLogConfig

+ (void)load
{
    if (self == [SentryTestLogConfig class]) {
        [SentryTestLogConfig setDefaultTestLogging];
    }
}

+ (void)setDefaultTestLogging
{
    [SentryLogSwiftSupport configure:YES diagnosticLevel:kSentryLevelDebug];
}

@end
