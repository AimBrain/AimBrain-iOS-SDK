#import "AMBNManager.h"
#import "AMBNAccelerometerCollector.h"
#import "AMBNServer.h"
#import "AMBNTextInputCollector.h"
#import "AMBNCapturingApplication.h"
#import "AMBNTouchCollector.h"
#import "AMBNFaceCaptureManager.h"
#import "AMBNImageAdapter.h"
#import "AMBNSessionCreateResult.h"
#import "AMBNBehaviouralResult.h"
#import "AMBNEnrollFaceResult.h"
#import "AMBNAuthenticateResult.h"
#import "AMBNCompareFaceResult.h"
#import "AMBNNetworkClient.h"
#import "AMBNSerializedRequest.h"
#import "Voice/AMBNVoiceRecordingViewController.h"
#import "AMBNVoiceRecordingManager.h"
#import "Result/AMBNEnrollVoiceResult.h"
#import "Result/AMBNVoiceTextResult.h"

#define AMBNManagerSensitiveSaltLength 128
@interface AMBNManager ()

@property AMBNAccelerometerCollector * accelerometerCollector;
@property AMBNTouchCollector * touchCollector;
@property AMBNTextInputCollector * textInputCollector;
@property NSHashTable *privacyGuards;
@property NSMutableArray *touches;
@property NSMutableArray *accelerations;
@property NSMutableArray *textEvents;
@property AMBNServer *server;
@property NSMapTable *registeredViews;
@property NSHashTable *sensitiveViews;
@property AMBNFaceCaptureManager* faceCaptureManager;
@property AMBNImageAdapter *imageAdapter;
@property AMBNVoiceRecordingManager *voiceRecordingManager;
@end
@implementation AMBNManager

+ (instancetype) sharedInstance{
    static AMBNManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype) init {
    self = [super init];
    self.imageAdapter = [[AMBNImageAdapter alloc] initWithQuality:0.7 maxHeight:300];
    self.privacyGuards = [NSHashTable weakObjectsHashTable];
    self.sensitiveViews = [NSHashTable weakObjectsHashTable];
    self.touches = [NSMutableArray array];
    self.accelerations = [NSMutableArray array];
    self.textEvents = [NSMutableArray array];

    self.accelerometerCollector = [[AMBNAccelerometerCollector alloc] initWithBuffer:self.accelerations collectionPeriod:0.5f updateInterval:0.01f];
    
    NSAssert([[UIApplication sharedApplication] isKindOfClass:[AMBNCapturingApplication class]], @"application must be of class AMBNCapturingApplication");
    AMBNCapturingApplication * application = (AMBNCapturingApplication *)[UIApplication sharedApplication];
    
    self.registeredViews = [NSMapTable weakToStrongObjectsMapTable];
    AMBNViewIdChainExtractor * idExtractor = [[AMBNViewIdChainExtractor alloc] initWithRegisteredViews:self.registeredViews];
    
    self.touchCollector = [[AMBNTouchCollector alloc] initWithBuffer:self.touches capturingApplication:application idExtractor:idExtractor];
    self.touchCollector.delegate = self;
    
    self.textInputCollector = [[AMBNTextInputCollector alloc] initWithBuffer:self.textEvents idExtractor:idExtractor];
    self.textInputCollector.delegate = self;
    
    self.faceCaptureManager = [[AMBNFaceCaptureManager alloc] init];
    self.voiceRecordingManager = [[AMBNVoiceRecordingManager alloc] init];
    return self;
}

- (void) start{
    _started = true;
    [self.textInputCollector start];
    
    id application = [UIApplication sharedApplication];
    NSAssert([application isKindOfClass:[AMBNCapturingApplication class]], @"sharedApplication must be of type: AMBNCapturingApplication");
}

- (void) configureWithApiKey: (NSString *) apiKey secret: (NSString *) appSecret {
    self.server = [[AMBNServer alloc] initWithNetworkClient:[[AMBNNetworkClient alloc] initWithApiKey:apiKey secret:appSecret]];
}

- (void) configureWithApiKey: (NSString *) apiKey secret: (NSString *) appSecret baseUrl:(NSString*)baseUrl {
    self.server = [[AMBNServer alloc] initWithNetworkClient:[[AMBNNetworkClient alloc] initWithApiKey:apiKey secret:appSecret baseUrl:baseUrl]];
}

- (void) createSessionWithUserId: (NSString *) userId completion: (void (^)(NSString * session, NSNumber * face, NSNumber * behaviour, NSError *error))completion {
    [self createSessionWithUserId: userId metadata:nil completionHandler:^(AMBNSessionCreateResult * result, NSError *error) {
        if (result != nil) {
            completion(result.session, result.face, result.behaviour, error);
        }
        else {
            completion(nil, 0, 0, error);
        }
    }];
}

- (void) createSessionWithUserId: (NSString *) userId completionHandler: (void (^)(AMBNSessionCreateResult *result, NSError *error))completion {
    [self createSessionWithUserId:userId metadata:nil completionHandler:completion];
}

- (void) createSessionWithUserId: (NSString *) userId metadata:(NSData *) metadata completionHandler: (void (^)(AMBNSessionCreateResult * result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    [self.server createSessionWithUserId:userId metadata:metadata completion:^(AMBNSessionCreateResult * result, NSError *error) {
        if (result != nil) {
            self.session = result.session;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedCreateSessionWithUserId:(NSString *)userId metadata:(NSData *)metadata {
    return [self.server serializeCreateSessionWithUserId:userId metadata:metadata];
}

- (void)submitBehaviouralDataWithCompletion:(void (^)(AMBNResult *result, NSError *error))completion {
    [self submitBehaviouralDataWithMetadata:nil completionHandler:^(AMBNBehaviouralResult *result, NSError *error) {
        if (result) {
            AMBNResult *wrappedResult = [[AMBNResult alloc] initWithScore:result.score status:result.status session:result.session];
            completion(wrappedResult, error);
        }
        else {
            completion(nil, error);
        }
    }];
}

- (void) submitBehaviouralDataWithCompletionHandler:(void (^)(AMBNBehaviouralResult * result, NSError *error))completion {
    [self submitBehaviouralDataWithMetadata:nil completionHandler:completion];
}

- (void)submitBehaviouralDataWithMetadata:(NSData *)metadata completionHandler:(void (^)(AMBNBehaviouralResult *result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");
    NSArray *touchesToSubmit;
    @synchronized (self.touches) {
        touchesToSubmit = [NSArray arrayWithArray:self.touches];
        [self.touches removeAllObjects];
    }
    NSArray *accelerationsToSubmit;
    @synchronized (self.accelerations) {
        accelerationsToSubmit = [NSArray arrayWithArray:self.accelerations];
        [self.accelerations removeAllObjects];
    }
    NSArray *textEventsToSubmit;
    @synchronized (self.textEvents) {
        textEventsToSubmit = [NSArray arrayWithArray:self.textEvents];
        [self.textEvents removeAllObjects];
    }

    [self.server submitTouches:touchesToSubmit accelerations:accelerationsToSubmit textEvents:textEventsToSubmit session:self.session metadata:metadata completion:^(AMBNBehaviouralResult *result, NSError *error) {
        if (error) {
            @synchronized (self.touches) {
                [self.touches addObjectsFromArray:touchesToSubmit];
            }
            @synchronized (self.accelerations) {
                [self.accelerations addObjectsFromArray:accelerationsToSubmit];
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:AMBNManagerBehaviouralDataSubmittedNotification object:result]];
            });

        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });

        return;
    }];
}

- (AMBNSerializedRequest *)getSerializedSubmitBehaviouralDataWithMetadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");
    NSArray *touchesToSubmit;
    @synchronized (self.touches) {
        touchesToSubmit = [NSArray arrayWithArray:self.touches];
        [self.touches removeAllObjects];
    }
    NSArray *accelerationsToSubmit;
    @synchronized (self.accelerations) {
        accelerationsToSubmit = [NSArray arrayWithArray:self.accelerations];
        [self.accelerations removeAllObjects];
    }
    NSArray *textEventsToSubmit;
    @synchronized (self.textEvents) {
        textEventsToSubmit = [NSArray arrayWithArray:self.textEvents];
        [self.textEvents removeAllObjects];
    }

    return [self.server serializeSubmitTouches:touchesToSubmit accelerations:accelerationsToSubmit textEvents:textEventsToSubmit session:self.session metadata:metadata];
}

- (void) getScoreWithCompletion:(void (^)(AMBNResult * result, NSError *error))completion{
    [self getScoreWithMetadata:nil completionHandler:^(AMBNBehaviouralResult *result, NSError *error) {
        if (result) {
            AMBNResult *wrappedResult = [[AMBNResult alloc] initWithScore:result.score status:result.status session:result.session];
            completion(wrappedResult, error);
        }
        else {
            completion(nil, error);
        }
    }];
}

- (void) getScoreWithCompletionHandler:(void (^)(AMBNBehaviouralResult * result, NSError *error))completion {
    [self getScoreWithMetadata:nil completionHandler:completion];
}

- (void) getScoreWithMetadata:(NSData *)metadata completionHandler:(void (^)(AMBNBehaviouralResult * result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");
    [self.server getScoreForSession:self.session metadata:metadata completion:completion];
}

- (AMBNSerializedRequest *)getSerializedGetScoreWithMetadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");
    return [self.server serializeScoreForSession:self.session metadata:metadata];
}

- (void)clearBehaviouralData {
    @synchronized (self.touches) {
        [self.touches removeAllObjects];
    }
    @synchronized (self.accelerations) {
        [self.accelerations removeAllObjects];
    }
    @synchronized (self.textEvents) {
        [self.textEvents removeAllObjects];
    }
}

- (void)registerView:(UIView *)view withId:(NSString *)identifier {
    [self.registeredViews setObject:identifier forKey:view];
}

- (void)addSensitiveViews:(NSArray *)views {
    for (UIView *view in views) {
        [self.sensitiveViews addObject:view];
    }
}

- (void)setSensitiveSalt:(NSData *)salt {
    NSString *error = [NSString stringWithFormat:@"Salt data length must be %i bits", AMBNManagerSensitiveSaltLength];
    NSAssert(salt.length == AMBNManagerSensitiveSaltLength, error);
    self.textInputCollector.sensitiveSalt = salt;
    self.touchCollector.sensitiveSalt = salt;
}

- (NSData *)generateRandomSensitiveSalt {
    NSMutableData *data = [NSMutableData dataWithLength:128];
    SecRandomCopyBytes(kSecRandomDefault, AMBNManagerSensitiveSaltLength, data.mutableBytes);
    return data;
}

- (AMBNPrivacyGuard *)disableCapturingForAllViews {
    AMBNPrivacyGuard *guard = [[AMBNPrivacyGuard alloc] initWithAllViews];
    [self.privacyGuards addObject:guard];
    return guard;
}

- (AMBNPrivacyGuard *)disableCapturingForViews:(NSArray *)views {
    AMBNPrivacyGuard *guard = [[AMBNPrivacyGuard alloc] initWithViews:views];
    [self.privacyGuards addObject:guard];
    return guard;
}

- (BOOL)isViewIgnored:(UIView *)view {
    for (AMBNPrivacyGuard *guard in [self.privacyGuards setRepresentation]) {
        if ([guard isViewIgnored:view]) {
            return true;
        }
    }
    return false;
}

- (BOOL)isViewSensitive:(UIView *)view {
    for (UIView *sensitiveView in self.sensitiveViews) {
        if ([view isDescendantOfView:sensitiveView]) {
            return true;
        }
    }
    return false;
}

- (BOOL)touchCollector:(id)touchCollector shouldTreatAsSenitive:(UIView *)view {
    return [self isViewSensitive:view];
}

- (void)textInputCollector:(id)textInputCollector didCollectTextInput:(AMBNTextEvent *)textEvent {
    [self.accelerometerCollector trigger];
}

- (BOOL)textInputCollector:(id)textInputCollector shouldTreatAsSenitive:(UIView *)view {
    return [self isViewSensitive:view];
}

- (BOOL)textInputCollector:(id)textInputCollector shouldIngoreEventForView:(UIView *)view {
    return [self isViewIgnored:view];
}

- (void)touchCollector:(id)touchCollector didCollectedTouch:(AMBNTouch *)touch {
    [self.accelerometerCollector trigger];
}

- (BOOL)touchCollector:(id)touchCollector shouldIgnoreTouchForView:(UIView *)view {
    return [self isViewIgnored:view];
}

- (void)enrollFaceImages:(NSArray *)images completion:(void (^)(BOOL, NSNumber *, NSError *))completion {
    [self enrollFaceImages:images metadata:nil completionHandler:^(AMBNEnrollFaceResult *result, NSError *error) {
        if (result) {
            completion(result.success, result.imagesCount, error);
        }
        else {
            completion(false, nil, error);
        }
    }];
}

- (void)enrollFaceImages:(NSArray *)images completionHandler:(void (^)(AMBNEnrollFaceResult *result, NSError *error))completion {
    [self enrollFaceImages:images metadata:nil completionHandler:completion];
}

- (void)enrollFaceImages:(NSArray *)images metadata:(NSData *)metadata completionHandler:(void (^)(AMBNEnrollFaceResult *result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");

    [self.server enrollFace:[self adaptImages:images] session:self.session metadata:metadata completion:^(AMBNEnrollFaceResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedEnrollFaceImages:(NSArray *)images metadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");

    return [self.server serializeEnrollFace:[self adaptImages:images] session:self.session metadata:metadata];
}

- (void)authenticateFaceImages:(NSArray *)images completion:(void (^)(NSNumber *score, NSNumber *liveliness, NSError *error))completion {
    [self authenticateFaceImages:images metadata:nil completionHandler:^(AMBNAuthenticateResult *result, NSError *error) {
        if (result) {
            completion(result.score, result.liveliness, error);
        }
        else {
            completion(nil, nil, error);
        }
    }];
}

- (void)authenticateFaceImages:(NSArray *)images completionHandler:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion {
    [self authenticateFaceImages:images metadata:nil completionHandler:completion];
}

- (void)authenticateFaceImages:(NSArray *)images metadata:(NSData *)metadata completionHandler:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");

    [self.server authFace:[self adaptImages:images] session:self.session metadata:metadata completion:^(AMBNAuthenticateResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedAuthenticateFaceImages:(NSArray *)images metadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");

    return [self.server serializeAuthFace:[self adaptImages:images] session:self.session metadata:metadata];
}

- (void)compareFaceImages:(NSArray *)firstFaceImages toFaceImages:(NSArray *)secondFaceImages completion:(void (^)(NSNumber *score, NSNumber *firstLiveliness, NSNumber *secondLiveliness, NSError *error))completion {
    [self compareFaceImages:firstFaceImages toFaceImages:secondFaceImages metadata:nil completionHandler:^(AMBNCompareFaceResult *result, NSError *error) {
        if (result) {
            completion(result.similarity, result.firstLiveliness, result.secondLiveliness, error);
        }
        else {
            completion(nil, nil, nil, error);
        }
    }];
}

- (void)compareFaceImages:(NSArray *)firstFaceImages toFaceImages:(NSArray *)secondFaceImages completionHandler:(void (^)(AMBNCompareFaceResult *result, NSError *error))completion {
    [self compareFaceImages:firstFaceImages toFaceImages:secondFaceImages metadata:nil completionHandler:completion];
}

- (void)compareFaceImages:(NSArray *)firstFaceImages toFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata completionHandler:(void (^)(AMBNCompareFaceResult *result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");

    [self.server compareFaceImages:[self adaptImages:firstFaceImages] withFaceImages:[self adaptImages:secondFaceImages] metadata:metadata completion:^(AMBNCompareFaceResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedCompareFaceImages:(NSArray *)firstFaceImages toFaceImages:(NSArray *)secondFaceImages metadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");
    return [self.server serializeCompareFaceImages:[self adaptImages:firstFaceImages] withFaceImages:[self adaptImages:secondFaceImages] metadata:metadata];
}

- (void)openFaceImagesCaptureWithTopHint:(NSString *)topHint bottomHint:(NSString *)bottomHint batchSize:(NSInteger)batchSize delay:(NSTimeInterval)delay fromViewController:(UIViewController *)viewController completion:(void (^)(NSArray *images, NSError *error))completion {
    [self.faceCaptureManager openCaptureViewFromViewController:viewController topHint:topHint bottomHint:bottomHint batchSize:batchSize delay:delay completion:completion];
}

- (AMBNFaceRecordingViewController *)instantiateFaceRecordingViewControllerWithVideoLength:(NSTimeInterval)videoLength {
    return [self.faceCaptureManager instantiateFaceRecordingViewControllerWithVideoLength:videoLength];
}

- (AMBNFaceRecordingViewController *)instantiateFaceRecordingViewControllerWithTopHint:(NSString *)topHint bottomHint:(NSString *)bottomHint recordingHint:(NSString *)recordingHint videoLength:(NSTimeInterval)videoLength {
    return [self.faceCaptureManager instantiateFaceRecordingViewControllerWithTopHint:topHint bottomHint:bottomHint recordingHint:recordingHint videoLength:videoLength];
}

- (void)enrollFaceVideo:(NSURL *)video completion:(void (^)(BOOL success, NSError *error))completion DEPRECATED_MSG_ATTRIBUTE("use enrollFaceVideo:completionHandler:") {
    [self enrollFaceVideo:video metadata:nil completionHandler:^(AMBNEnrollFaceResult *result, NSError *error) {
        if (result) {
            completion(result.success, error);
        }
        else {
            completion(NO, error);
        }
    }];
}

- (void)enrollFaceVideo:(NSURL *)video completionHandler:(void (^)(AMBNEnrollFaceResult *result, NSError *error))completion {
    [self enrollFaceVideo:video metadata:nil completionHandler:completion];
}

- (void)enrollFaceVideo:(NSURL *)video metadata:(NSData *)metadata completionHandler:(void (^)(AMBNEnrollFaceResult *result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");

    [self.server enrollFace:[self adaptVideo:video] session:self.session metadata:metadata completion:^(AMBNEnrollFaceResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedEnrollFaceVideo:(NSURL *)video metadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");
    return [self.server serializeEnrollFace:[self adaptVideo:video] session:self.session metadata:metadata];
}

- (void)authenticateFaceVideo:(NSURL *)video completion:(void (^)(NSNumber *score, NSNumber *liveliness, NSError *error))completion {
    [self authenticateFaceVideo:video metadata:nil completionHandler:^(AMBNAuthenticateResult *result, NSError *error) {
        if (result) {
            completion(result.score, result.liveliness, error);
        }
        else {
            completion(nil, nil, error);
        }
    }];
}

- (void)authenticateFaceVideo:(NSURL *)video completionHandler:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion {
    [self authenticateFaceVideo:video metadata:nil completionHandler:completion];
}

- (void)authenticateFaceVideo:(NSURL *)video metadata:(NSData *)metadata completionHandler:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");

    [self.server authFace:[self adaptVideo:video] session:self.session metadata:metadata completion:^(AMBNAuthenticateResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedAuthenticateFaceVideo:(NSURL *)video metadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");
    return [self.server serializeAuthFace:[self adaptVideo:video] session:self.session metadata:metadata];
}

- (NSArray *)adaptImages:(NSArray *)images {
    NSMutableArray *adaptedImages = [NSMutableArray array];
    for (UIImage *image in images) {
        [adaptedImages addObject:[self.imageAdapter encodedImage:image]];
    }
    return adaptedImages;
}

- (NSArray *)adaptVideo:(NSURL *)video {
    NSMutableArray *adaptedVideos = [NSMutableArray array];
    NSData *videoData = [NSData dataWithContentsOfURL:video];
    if ([videoData respondsToSelector:@selector(base64Encoding)]) {
        [adaptedVideos addObject:[videoData base64Encoding]];
    } else {
        [adaptedVideos addObject:[videoData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
    }

    return adaptedVideos;
}


- (AMBNVoiceRecordingViewController *) instantiateVoiceRecordingViewControllerWithAudioLength:(NSTimeInterval)audioLength {
    return [self.voiceRecordingManager instantiateVoiceRecordingViewControllerWithAudioLength:audioLength];
}

- (AMBNVoiceRecordingViewController *) instantiateVoiceRecordingViewControllerWithTopHint:(NSString *)topHint bottomHint:(NSString *)bottomHint recordingHint:(NSString *)recordingHint audioLength:(NSTimeInterval)audioLength {
    return [self.voiceRecordingManager instantiateVoiceRecordingViewControllerWithTopHint:topHint bottomHint:bottomHint recordingHint:recordingHint audioLength:audioLength];
}

- (void)enrollVoice:(NSURL *)voiceFileUrl completionHandler:(void (^)(AMBNEnrollVoiceResult *result, NSError *))completion {
    [self enrollVoice:voiceFileUrl metadata:nil completionHandler:completion];
}

- (void)enrollVoice:(NSURL *)voiceFileUrl metadata:(NSData *)metadata completionHandler:(void (^)(AMBNEnrollVoiceResult *result, NSError *))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");
    NSAssert(voiceFileUrl != nil, @"Voice record file url is not provided");

    [self.server enrollVoice:[self voiceRecordToBase64:voiceFileUrl] session:self.session metadata:metadata completion:^(AMBNEnrollVoiceResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedEnrollVoice:(NSURL *)voiceFileUrl metadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");
    NSAssert(voiceFileUrl != nil, @"Voice record file url is not provided");
    return [self.server serializeEnrollVoice:[self voiceRecordToBase64:voiceFileUrl] session:self.session metadata:metadata];
}

- (void)authenticateVoice:(NSURL*)voiceUrl completionHandler:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion {
    [self authenticateVoice:voiceUrl metadata:nil completionHandler:completion];
}

- (void)authenticateVoice:(NSURL*)voiceUrl metadata:(NSData *)metadata completionHandler:(void (^)(AMBNAuthenticateResult *result, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");
    NSAssert(voiceUrl != nil, @"Voice record file url is not provided");

    [self.server authVoice:[self voiceRecordToBase64:voiceUrl] session:self.session metadata:metadata completion:^(AMBNAuthenticateResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedAuthenticateVoice:(NSURL *)voiceFileUrl metadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");
    NSAssert(voiceFileUrl != nil, @"Voice record file url is not provided");
    return [self.server serializeAuthVoice:[self voiceRecordToBase64:voiceFileUrl] session:self.session metadata:metadata];
}

- (void)getVoiceTokenWithType:(AMBNVoiceTokenType)type completionHandler:(void (^)(AMBNVoiceTextResult *, NSError *))completion {
    [self getVoiceTokenWithType:type metadata:nil completionHandler:completion];
}

- (void)getVoiceTokenWithType:(AMBNVoiceTokenType)type metadata:(NSData *)metadata completionHandler:(void (^)(AMBNVoiceTextResult *result, NSError * error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");

    NSString *tokenType = [self voiceTokenString:type];
    NSAssert(tokenType != nil, @"Correct token type not supplied");

    [self.server getVoiceTokenForSession:self.session type:tokenType metadata:metadata completion:^(AMBNVoiceTextResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    }];
}

- (AMBNSerializedRequest *)getSerializedGetVoiceTokenWithType:(AMBNVoiceTokenType)type metadata:(NSData *)metadata {
    NSAssert(self.session != nil, @"Session is not obtained");
    NSString *tokenType = [self voiceTokenString:type];
    NSAssert(tokenType != nil, @"Correct token type not supplied");
    return [self.server serializeGetVoiceTokenForSession:self.session type:tokenType metadata:metadata];
}

-(NSString *)voiceTokenString:(AMBNVoiceTokenType)type {
    switch (type) {
        case AMBNVoiceTokenTypeEnroll1:
            return @"enroll-1";
        case AMBNVoiceTokenTypeEnroll2:
            return @"enroll-2";
        case AMBNVoiceTokenTypeEnroll3:
            return @"enroll-3";
        case AMBNVoiceTokenTypeEnroll4:
            return @"enroll-4";
        case AMBNVoiceTokenTypeEnroll5:
            return @"enroll-5";
        case AMBNVoiceTokenTypeAuth:
            return @"auth";
    }
    return nil;
}

- (NSString *)voiceRecordToBase64:(NSURL *)voiceUrl {
    NSData *data = [NSData dataWithContentsOfURL:voiceUrl];
    if ([data respondsToSelector:@selector(base64Encoding)]) {
        return [data base64Encoding];
    }
    else {
        return [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    }
}

@end
