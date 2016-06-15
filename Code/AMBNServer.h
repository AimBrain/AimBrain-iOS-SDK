#import <Foundation/Foundation.h>
#import "AMBNResult.h"

#define AMBNServerErrorDomain @"AMBNServerErrorDomain"
#define AMBNServerMissingJSONKeyError 1
#define AMBNServerWrongResponseFormatError 2
#define AMBNServerHTTPNotFoundError 3
#define AMBNServerHTTPUnauthorizedError 4
#define AMBNServerHTTPUnknownError 4

@interface AMBNServer : NSObject

- (instancetype) initWithApiKey: (NSString *) apiKey secret: (NSString *) secret;
- (instancetype) initWithApiKey: (NSString *) apiKey secret: (NSString *) secret baseUrl:(NSString*)baseUrl;

- (void) createSessionWithUserId: (NSString *)userId completion: (void (^)(NSString * session, NSNumber * face, NSNumber * behaviour, NSError * error))completion;

- (void) submitTouches: (NSArray *) touches accelerations: (NSArray *) accelerations textEvents: (NSArray *) textEvents session: (NSString *) session completion: (void (^)(AMBNResult * result, NSError * error))completion ;
- (void) getScoreForSession: (NSString *) session completion: (void (^)(AMBNResult * result, NSError * error))completion;

- (void) enrollFace: (NSArray *) dataToEnroll session: (NSString*) session completion: (void (^)(BOOL success, NSNumber * imagesCount, NSError * error))completion;
- (void) authFace: (NSArray *) dataToAuth session: (NSString*) session completion: (void (^)(NSNumber * score, NSNumber * liveliness, NSError * error))completion;
- (void) compareFaceImages: (NSArray *) firstFaceImages withFaceImages: (NSArray *) secondFaceImages completion: (void (^)(NSNumber * smilarity, NSNumber * firstLiveliness, NSNumber * secondLiveliness, NSError * error))completion;

@end
