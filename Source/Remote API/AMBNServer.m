#import "AMBNServer.h"
#import "AMBNSessionCreateResult.h"
#import "AMBNBehaviouralResult.h"
#import "AMBNEnrollFaceResult.h"
#import "AMBNAuthenticateResult.h"
#import "AMBNCompareFaceResult.h"
#import "AMBNTouch.h"
#import "AMBNAcceleration.h"
#import "AMBNTextEvent.h"
#import "AMBNNetworkClient.h"
#import "AMBNSerializedRequest.h"
#import "AMBNEnrollVoiceResult.h"
#import "AMBNVoiceTextResult.h"
#import "AMBNTextResult.h"
#import <sys/utsname.h>

#import "AMBNGlobal.h"


@interface AMBNServer ()
@property(nonatomic, strong) AMBNNetworkClient* client;
@property(nonatomic, strong) NSOperationQueue *queue;
@end

@implementation AMBNServer

- (instancetype)initWithNetworkClient:(AMBNNetworkClient *)client {
    self = [super init];
    if (self) {
        self.queue = [[NSOperationQueue alloc] init];
        self.client = client;
    }
    return self;
}

- (void)createSessionWithUserId:(NSString *)userId metadata:(NSData *)metadata completion:(void (^)(AMBNSessionCreateResult *result, NSError *error))completion {
    id data = [self JSONOfCreateSessionWithUserId:userId metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNCreateSessionEndpoint];
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (![responseJSON isKindOfClass:[NSDictionary class]]) {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *) responseJSON;
        NSNumber *face = jsonDict[@"face"];
        NSNumber *voice = jsonDict[@"voice"];
        NSNumber *behaviour = jsonDict[@"behaviour"];
        NSString *session = jsonDict[@"session"];
        NSString *metadataString = jsonDict[@"metadata"];
        if (session && face && behaviour) {
            NSData *responseMetadata = nil;
            if (metadataString) {
                responseMetadata = [[NSData alloc] initWithBase64EncodedString:metadataString options:0];
            }
            AMBNSessionCreateResult *result = [[AMBNSessionCreateResult alloc] initWithFace:face voice:voice behaviour:behaviour session:session metadata:responseMetadata];
            completion(result, nil);
            return;
        } else {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }];
}

- (AMBNSerializedRequest *)serializeCreateSessionWithUserId:(NSString *)userId metadata:(NSData *)metadata {
    id data = [self JSONOfCreateSessionWithUserId:userId metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfCreateSessionWithUserId:(NSString *)userId metadata:(NSData *)metadata {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"userId" : userId,
                                                                                }];
    
    [self addSessionCreateParameters:json];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)submitTouches:(NSArray *)touches accelerations:(NSArray *)accelerations textEvents:(NSArray *)textEvents session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNBehaviouralResult *result, NSError *error))completion {
    [self.queue addOperationWithBlock:^{
        [self sendSubmitTouches:touches accelerations:accelerations textEvents:textEvents session:session metadata:metadata completion:completion];
    }];
}

- (void)sendSubmitTouches:(NSArray *)touches accelerations:(NSArray *)accelerations textEvents:(NSArray *)textEvents session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNBehaviouralResult *result, NSError *error))completion {
    id data = [self JSONOfSubmitTouches:touches accelerations:accelerations textEvents:textEvents session:session metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNSubmitBehaviouralEndpoint];
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        [self handleScoreResponse:responseJSON session:session error:error completion:completion];
    }];
}

- (AMBNSerializedRequest *)serializeSubmitTouches:(NSArray *)touches accelerations:(NSArray *)accelerations textEvents:(NSArray *)textEvents session:(NSString *)session metadata:(NSData *)metadata {
    id data = [self JSONOfSubmitTouches:touches accelerations:accelerations textEvents:textEvents session:session metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfSubmitTouches:(NSArray *)touches accelerations:(NSArray *)accelerations textEvents:(NSArray *)textEvents session:(NSString *)session metadata:(NSData *)metadata {
    NSMutableArray *touchesJSON = [NSMutableArray array];
    for (AMBNTouch * touch in touches){
        [touchesJSON addObject:@{
                                 @"tid" : @(touch.touchId),
                                 @"t" : @(touch.timestamp),
                                 @"r" : @(touch.radius),
                                 @"x" : @(touch.absoluteLocation.x),
                                 @"y" : @(touch.absoluteLocation.y),
                                 @"rx" : @(touch.relativeLocation.x),
                                 @"ry" : @(touch.relativeLocation.y),
                                 @"f" : @(touch.force),
                                 @"p" : @(touch.phase),
                                 @"ids" : touch.identifiers
                                 }];
    }
    
    NSMutableArray *accelerationsJSON = [NSMutableArray array];
    for(AMBNAcceleration * acc in accelerations){
        [accelerationsJSON addObject:@{
                                       @"t" : @(acc.timestamp),
                                       @"x" : @(acc.x),
                                       @"y" : @(acc.y),
                                       @"z" : @(acc.z),
                                       }];
    }
    
    NSMutableArray *textEventsJSON = [NSMutableArray array];
    for (AMBNTextEvent * textEvent in textEvents){
        [textEventsJSON addObject:@{
                                    @"t" : @(textEvent.timestamp),
                                    @"tx" : textEvent.text,
                                    @"ids": textEvent.identifiers
                                    }];
    }
    
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"session" : session,
                                                                                @"touches" : touchesJSON,
                                                                                @"accelerations" : accelerationsJSON,
                                                                                @"textEvents" : textEventsJSON
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)getScoreForSession:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNBehaviouralResult *result, NSError *error))completion {
    [self.queue addOperationWithBlock:^{
        [self sendGetScoreForSession:session metadata:metadata completion:completion];
    }];
}

- (void)sendGetScoreForSession:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNBehaviouralResult *result, NSError *error))completion {
    id data = [self JSONOfScoreForSession:session metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNGetScoreEndpoint];
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        [self handleScoreResponse:responseJSON session:session error:error completion:completion];
    }];
}

- (id)JSONOfScoreForSession:(NSString *)session metadata:(NSData *)metadata {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"session" : session
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (AMBNSerializedRequest *)serializeScoreForSession:(NSString *)session metadata:(NSData *)metadata {
    id data = [self JSONOfScoreForSession:session metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (void)handleScoreResponse:(_Nullable id)responseJSON session:(NSString *)session error:(NSError *)error completion:(void (^)(AMBNBehaviouralResult *result, NSError *error))completion {
    if (error) {
        completion(nil, error);
        return;
    }
    
    if (![responseJSON isKindOfClass:[NSDictionary class]]) {
        completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
        return;
    }
    
    NSDictionary *jsonDict = (NSDictionary *) responseJSON;
    NSNumber *score = jsonDict[@"score"];
    NSNumber *status = jsonDict[@"status"];
    NSString *metadataString = jsonDict[@"metadata"];
    if (score && status) {
        NSData *responseMetadata = nil;
        if (metadataString) {
            responseMetadata = [[NSData alloc] initWithBase64EncodedString:metadataString options:0];
        }
        completion([[AMBNBehaviouralResult alloc] initWithScore:score status:[status integerValue] session:session metadata:responseMetadata], nil);
        return;
    } else {
        completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
        return;
    }
}

- (void)authFace:(NSArray *)dataToAuth session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion {
    [self.queue addOperationWithBlock:^{
        [self sendAuthFace:(NSArray *)dataToAuth session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion];
    }];
}

- (void)sendAuthFace:(NSArray *)dataToAuth session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion {
    id data = [self JSONOfAuthFace:dataToAuth session:session metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNFacialAuthEndpoint];
    [self sendAuthFaceRequest:completion request:request];
}

- (AMBNSerializedRequest *)serializeAuthFace:(NSArray *)dataToAuth session:(NSString *)session metadata:(NSData *)metadata  {
    id data = [self JSONOfAuthFace:dataToAuth session:session metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfAuthFace:(NSArray *)dataToAuth session:(NSString *)session metadata:(NSData *)metadata  {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"session" : session,
                                                                                @"faces" : dataToAuth
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)sendAuthFaceRequest:(void (^)(AMBNAuthenticateResult *, NSError *))completion request:(NSMutableURLRequest *)request {
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (![responseJSON isKindOfClass:[NSDictionary class]]) {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *) responseJSON;
        NSNumber *score = jsonDict[@"score"];
        NSNumber *liveliness = jsonDict[@"liveliness"];
        NSString *responseMetadataString = jsonDict[@"metadata"];
        if (score && liveliness) {
            NSData *responseMetadata = nil;
            if (responseMetadataString) {
                responseMetadata = [[NSData alloc] initWithBase64EncodedString:responseMetadataString options:0];
            }
            completion([[AMBNAuthenticateResult alloc] initWithScore:score liveliness:liveliness metadata:responseMetadata], nil);
            return;
        } else {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }];
}

- (void)enrollFace:(NSArray *)dataToEnroll session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNEnrollFaceResult *result, NSError *error))completion {
    [self.queue addOperationWithBlock:^{
        [self sendEnrollFace:(NSArray *)dataToEnroll session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNEnrollFaceResult *result, NSError *error))completion];
    }];
}

- (void)sendEnrollFace:(NSArray *)dataToEnroll session:(NSString *)session metadata:(NSData *)metadata completion:(void (^)(AMBNEnrollFaceResult *result, NSError *error))completion {
    id data = [self JSONOfEnrollFace:dataToEnroll session:session metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNFacialEnrollEndpoint];
    [self sendEnrollFaceRequest:completion request:request];
}

- (AMBNSerializedRequest *)serializeEnrollFace:(NSArray *)dataToEnroll session:(NSString *)session metadata:(NSData *)metadata  {
    id data = [self JSONOfEnrollFace:dataToEnroll session:session metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfEnrollFace:(NSArray *)dataToEnroll session:(NSString *)session metadata:(NSData *)metadata   {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"session" : session,
                                                                                @"faces" : dataToEnroll
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)sendEnrollFaceRequest:(void (^)(AMBNEnrollFaceResult *, NSError *))completion request:(NSMutableURLRequest *)request {
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (![responseJSON isKindOfClass:[NSDictionary class]]) {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *) responseJSON;
        NSNumber *imagesCount = jsonDict[@"imagesCount"];
        NSString *responseMetadataString = jsonDict[@"metadata"];
        if (imagesCount) {
            NSData *responseMetadata = nil;
            if (responseMetadataString) {
                responseMetadata = [[NSData alloc] initWithBase64EncodedString:responseMetadataString options:0];
            }
            completion([[AMBNEnrollFaceResult alloc] initWithSuccess:true imagesCount:imagesCount metadata:responseMetadata], nil);
            return;
        } else {
            completion([[AMBNEnrollFaceResult alloc] initWithSuccess:true imagesCount:nil metadata:nil], [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }];
}

- (void)compareFaceImages:(NSArray *)firstFaceImages withFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata completion:(void (^)(AMBNCompareFaceResult *result, NSError *error))completion {
    [self.queue addOperationWithBlock:^{
        [self sendCompareFaceImages:(NSArray *)firstFaceImages withFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata completion:(void (^)(AMBNCompareFaceResult *result, NSError *error))completion];
    }];
}

- (void)sendCompareFaceImages:(NSArray *)firstFaceImages withFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata completion:(void (^)(AMBNCompareFaceResult *result, NSError *error))completion {
    id data = [self JSONOfCompareFaceImages:firstFaceImages withFaceImages:secondFaceImages metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNFacialCompareEndpoint];
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (![responseJSON isKindOfClass:[NSDictionary class]]) {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *) responseJSON;
        NSNumber *similarity = jsonDict[@"score"];
        NSNumber *firstLiveliness = jsonDict[@"liveliness1"];
        NSNumber *secondLiveliness = jsonDict[@"liveliness2"];
        NSString *responseMetadataString = jsonDict[@"metadata"];
        
        if (similarity && firstLiveliness && secondLiveliness) {
            NSData *responseMetadata = nil;
            if (responseMetadataString) {
                responseMetadata = [[NSData alloc] initWithBase64EncodedString:responseMetadataString options:0];
            }
            AMBNCompareFaceResult *result = [[AMBNCompareFaceResult alloc] initWithSimilarity:similarity firstLiveliness:firstLiveliness secondLiveliness:secondLiveliness metadata:responseMetadata];
            completion(result, nil);
            return;
        } else {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }];
}

- (AMBNSerializedRequest *)serializeCompareFaceImages:(NSArray *)firstFaceImages withFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata {
    id data = [self JSONOfCompareFaceImages:firstFaceImages withFaceImages:secondFaceImages metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfCompareFaceImages:(NSArray *)firstFaceImages withFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"faces1" : firstFaceImages,
                                                                                @"faces2" : secondFaceImages
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)enrollVoice: (NSString *)dataToEnroll session: (NSString*) session metadata:(NSData *)metadata completion: (void (^)(AMBNEnrollVoiceResult *result, NSError * error))completion {
    NSAssert(dataToEnroll != nil, @"Voice record data for enroll is not provided");
    
    [self.queue addOperationWithBlock:^{
        [self sendEnrollVoice: (NSString *)dataToEnroll session: (NSString*) session metadata:(NSData *)metadata completion: (void (^)(AMBNEnrollVoiceResult *result, NSError * error))completion];
    }];
}

- (void)sendEnrollVoice: (NSString *)dataToEnroll session: (NSString*) session metadata:(NSData *)metadata completion: (void (^)(AMBNEnrollVoiceResult *result, NSError * error))completion {
    NSAssert(dataToEnroll != nil, @"Voice record data for enroll is not provided");
    
    id data = [self JSONOfEnrollVoice:dataToEnroll session:session metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNVoiceEnrollEndpoint];
    [self sendEnrollVoiceRequest:completion request:request];
}

- (AMBNSerializedRequest *)serializeEnrollVoice: (NSString *)dataToEnroll session: (NSString*) session metadata:(NSData *)metadata {
    id data = [self JSONOfEnrollVoice:dataToEnroll session:session metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfEnrollVoice:(NSString *)voiceData session:(NSString *)sessionId metadata:(NSData *)metadata {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"session" : sessionId,
                                                                                @"voices" : @[voiceData]
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)sendEnrollVoiceRequest:(void (^)(AMBNEnrollVoiceResult *, NSError *))completion request:(NSMutableURLRequest *)request {
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (![responseJSON isKindOfClass:[NSDictionary class]]) {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *) responseJSON;
        NSNumber *voiceSamples = jsonDict[@"voiceSamples"];
        NSString *responseMetadataString = jsonDict[@"metadata"];
        NSData *responseMetadata = nil;
        if (responseMetadataString) {
            responseMetadata = [[NSData alloc] initWithBase64EncodedString:responseMetadataString options:0];
        }
        
        if (voiceSamples) {
            AMBNEnrollVoiceResult *result = [[AMBNEnrollVoiceResult alloc] initWithSuccess:true samplesCount:voiceSamples metadata:responseMetadata];
            completion(result, nil);
        } else {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }];
}

- (void)authVoice:(NSString*) dataToAuth session: (NSString*) session metadata:(NSData *)metadata completion: (void (^)(AMBNAuthenticateResult *result, NSError * error))completion {
    NSAssert(dataToAuth != nil, @"Voice record data for auth is not provided");
    
    [self.queue addOperationWithBlock:^{
        [self sendAuthVoice:(NSString*) dataToAuth session: (NSString*) session metadata:(NSData *)metadata completion: (void (^)(AMBNAuthenticateResult *result, NSError * error))completion];
    }];
}

- (void)sendAuthVoice:(NSString*) dataToAuth session: (NSString*) session metadata:(NSData *)metadata completion: (void (^)(AMBNAuthenticateResult *result, NSError * error))completion {
    NSAssert(dataToAuth != nil, @"Voice record data for auth is not provided");
    
    id data = [self JSONOfAuthVoice:dataToAuth session:session metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNVoiceAuthEndpoint];
    [self sendAuthVoice:completion request:request];
}

- (AMBNSerializedRequest *)serializeAuthVoice: (NSString *)dataToAuth session: (NSString*) session metadata:(NSData *)metadata {
    id data = [self JSONOfAuthVoice:dataToAuth session:session metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfAuthVoice:(NSString *)voiceData session:(NSString *)session metadata:(NSData *)metadata {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"session" : session,
                                                                                @"voices" : @[voiceData]
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)sendAuthVoice:(void (^)(AMBNAuthenticateResult *, NSError *))completion request:(NSMutableURLRequest *)request {
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (![responseJSON isKindOfClass:[NSDictionary class]]) {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *) responseJSON;
        NSNumber *score = jsonDict[@"score"];
        NSNumber *liveliness = jsonDict[@"liveliness"];
        NSString *responseMetadataString = jsonDict[@"metadata"];
        NSData *responseMetadata = nil;
        if (responseMetadataString) {
            responseMetadata = [[NSData alloc] initWithBase64EncodedString:responseMetadataString options:0];
        }
        
        if (score && liveliness) {
            completion([[AMBNAuthenticateResult alloc] initWithScore:score liveliness:liveliness metadata:responseMetadata], nil);
            return;
        } else {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }];
}

#pragma mark - GET VOICE TOKEN

- (void)getVoiceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata completion:(void (^)(AMBNVoiceTextResult *result, NSError * error))completion {
    [self.queue addOperationWithBlock:^{
        [self sendGetVoiceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata completion:(void (^)(AMBNVoiceTextResult *result, NSError * error))completion];
    }];
}

- (void)sendGetVoiceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata completion:(void (^)(AMBNVoiceTextResult *result, NSError * error))completion {
    id data = [self JSONOfGetVoiceTokenForSession:session type:type metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNVoiceTokenEndpoint];
    [self sendVoiceTokenRequest:completion request:request];
}

- (AMBNSerializedRequest *)serializeGetVoiceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata  {
    id data = [self JSONOfGetVoiceTokenForSession:session type:type metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfGetVoiceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"session" : session,
                                                                                @"tokentype": type
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)sendVoiceTokenRequest:(void (^)(AMBNVoiceTextResult *, NSError *))completion request:(NSMutableURLRequest *)request {
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (![responseJSON isKindOfClass:[NSDictionary class]]) {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *) responseJSON;
        NSString *token = jsonDict[@"token"];
        NSString *responseMetadataString = jsonDict[@"metadata"];
        NSData *responseMetadata = nil;
        if (responseMetadataString) {
            responseMetadata = [[NSData alloc] initWithBase64EncodedString:responseMetadataString options:0];
        }
        
        if (token) {
            completion([[AMBNVoiceTextResult alloc] initWithTokenText:token metadata:responseMetadata], nil);
            return;
        } else {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }];
}

#pragma mark - GET FACE TOKEN

- (void)getFaceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata completion:(void (^)(AMBNTextResult *result, NSError * error))completion {
    [self.queue addOperationWithBlock:^{
        [self sendGetFaceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata completion:(void (^)(AMBNTextResult *result, NSError * error))completion];
    }];
}

- (void)sendGetFaceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata completion:(void (^)(AMBNTextResult *result, NSError * error))completion {
    id data = [self JSONOfGetFaceTokenForSession:session type:type metadata:metadata];
    NSMutableURLRequest *request = [self.client createJSONPOSTWithData:data endpoint:AMBNFaceTokenEndpoint];
    [self sendFaceTokenRequest:completion request:request];
}

- (AMBNSerializedRequest *)serializeGetFaceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata  {
    id data = [self JSONOfGetFaceTokenForSession:session type:type metadata:metadata];
    return [self.client serializeRequestData:data];
}

- (id)JSONOfGetFaceTokenForSession:(NSString *)session type:(NSString *)type metadata:(NSData *)metadata {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"session" : session,
                                                                                @"tokentype": type
                                                                                }];
    
    if (metadata) {
        json[@"metadata"] = [metadata base64EncodedStringWithOptions:0];
    }
    
    return json;
}

- (void)sendFaceTokenRequest:(void (^)(AMBNTextResult *, NSError *))completion request:(NSMutableURLRequest *)request {
    [self.client sendRequest:request queue:self.queue completionHandler:^(id _Nullable responseJSON, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (![responseJSON isKindOfClass:[NSDictionary class]]) {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSDictionary *jsonDict = (NSDictionary *) responseJSON;
        NSString *token = jsonDict[@"token"];
        NSString *responseMetadataString = jsonDict[@"metadata"];
        NSData *responseMetadata = nil;
        if (responseMetadataString) {
            responseMetadata = [[NSData alloc] initWithBase64EncodedString:responseMetadataString options:0];
        }
        
        if (token) {
            completion([[AMBNTextResult alloc] initWithTokenText:token metadata:responseMetadata], nil);
            return;
        } else {
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }];
}

- (BOOL)isClientValid {
    return [self.client canSendRequests];
}

#pragma mark -

-(void)addSessionCreateParameters:(NSMutableDictionary *)params {
    UIDevice *currentDevice = [UIDevice currentDevice];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    params[@"system"] = [NSString stringWithFormat:@"iOS %@", currentDevice.systemVersion],
    params[@"device"] = [self machineName],
    params[@"screenWidth"] = @(screenRect.size.width);
    params[@"screenHeight"] = @(screenRect.size.height);
}

- (NSString *)machineName {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@end
