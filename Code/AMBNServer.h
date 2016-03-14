#import <Foundation/Foundation.h>
#import "AMBNResult.h"

#define AMBNServerErrorDomain @"AMBNServerErrorDomain"
#define AMBNServerMissingJSONKeyError 1
#define AMBNServerWrongResponseFormatError 2
#define AMBNServerHTTPNotFoundError 3
#define AMBNServerHTTPUnauthorizedError 4
#define AMBNServerHTTPUnknownError 4

@interface AMBNServer : NSObject

- (instancetype) initWithAppId: (NSString *) appId secret: (NSString *) secret;

- (void) createSessionWithUserId: (NSString *)userId completion: (void (^)(NSString * session, NSError * error))completion;
- (void) submitTouches: (NSArray *) touches accelerations: (NSArray *) accelerations textEvents: (NSArray *) textEvents session: (NSString *) session completion: (void (^)(AMBNResult * result, NSError * error))completion ;
- (void) getScoreForSession: (NSString *) session completion: (void (^)(AMBNResult * score, NSError * error))completion;
@end
