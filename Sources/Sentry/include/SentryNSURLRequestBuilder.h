#import <Foundation/Foundation.h>

@class SentryDsn;
@class SentryEnvelope;

NS_ASSUME_NONNULL_BEGIN

/**
 * A wrapper around SentryNSURLRequest for testability
 */
@interface SentryNSURLRequestBuilder : NSObject

- (nullable NSURLRequest *)createEnvelopeRequest:(SentryEnvelope *)envelope
                                             dsn:(SentryDsn *)dsn
                                didFailWithError:(NSError *_Nullable *_Nullable)error;

- (nullable NSURLRequest *)createEnvelopeRequest:(SentryEnvelope *)envelope
                                             url:(NSURL *)url
                                didFailWithError:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
