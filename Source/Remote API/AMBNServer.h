#import <Foundation/Foundation.h>
#import "AMBNResult.h"

#define AMBNServerErrorDomain @"AMBNServerErrorDomain"
#define AMBNServerMissingJSONKeyError 1
#define AMBNServerWrongResponseFormatError 2
#define AMBNServerHTTPNotFoundError 3
#define AMBNServerHTTPUnauthorizedError 4
#define AMBNServerHTTPUnknownError 4

@class AMBNSessionCreateResult;
@class AMBNBehaviouralResult;
@class AMBNEnrollFaceResult;
@class AMBNAuthenticateFaceResult;
@class AMBNCompareFaceResult;
@class AMBNNetworkClient;
@class AMBNSerializedRequest;

@interface AMBNServer : NSObject
- (instancetype)initWithNetworkClient:(AMBNNetworkClient *)client;

- (void)createSessionWithUserId:(NSString *)userId metadata:(NSData *)metadata completion:(void (^)(AMBNSessionCreateResult *result, NSError *error))completion;

- (AMBNSerializedRequest *)serializeCreateSessionWithUserId:(NSString *)userId metadata:(NSData *)metadata;

- (void)submitTouches:(NSArray *)touches accelerations:(NSArray *)accelerations textEvents:(NSArray *)textEvents session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNBehaviouralResult *result, NSError *error))completion;

- (AMBNSerializedRequest *)serializeSubmitTouches:(NSArray *)touches accelerations:(NSArray *)accelerations textEvents:(NSArray *)textEvents session:(NSString *)session metadata:(NSData *)metadata;

- (void)getScoreForSession:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNBehaviouralResult *result, NSError *error))completion;

- (AMBNSerializedRequest *)serializeScoreForSession:(NSString *)session metadata:(NSData *)metadata;

- (void)authFace:(NSArray *)dataToAuth session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNAuthenticateFaceResult *result, NSError *error))completion;

- (AMBNSerializedRequest *)serializeAuthFace:(NSArray *)dataToAuth session:(NSString *)session metadata:(NSData *)metadata;

- (void)compareFaceImages:(NSArray *)firstFaceImages withFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata completion:(void (^)(AMBNCompareFaceResult *result, NSError *error))completion;

- (AMBNSerializedRequest *)serializeCompareFaceImages:(NSArray *)firstFaceImages withFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata;

- (void)enrollFace:(NSArray *)dataToEnroll session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNEnrollFaceResult *result, NSError *error))completion;

- (AMBNSerializedRequest *)serializeEnrollFace:(NSArray *)dataToEnroll session:(NSString *)session metadata:(NSData *)metadata;
@end
