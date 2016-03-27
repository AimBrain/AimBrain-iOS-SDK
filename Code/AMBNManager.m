#import "AMBNManager.h"
#import "AMBNAccelerometerCollector.h"
#import "AMBNServer.h"
#import "AMBNTextInputCollector.h"
#import "AMBNCapturingApplication.h"
#import "AMBNTouchCollector.h"
#import "AMBNFaceCaptureManager.h"
#import "AMBNImageAdapter.h"

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

- (instancetype) init{
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
    return self;
}

- (void) start{
    _started = true;
    [self.textInputCollector start];
    
    id application = [UIApplication sharedApplication];
    NSAssert([application isKindOfClass:[AMBNCapturingApplication class]], @"sharedApplication must be of type: AMBNCapturingApplication");
}

- (void) configureWithApplicationId: (NSString *) appId secret: (NSString *) appSecret{
    self.server = [[AMBNServer alloc] initWithAppId:appId secret:appSecret];
}

- (void) createSessionWithUserId: (NSString *) userId completion: (void (^)(NSString * session, NSNumber * face, NSNumber * behaviour, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    [self.server createSessionWithUserId:userId completion:^(NSString *session, NSNumber * face, NSNumber * behaviour, NSError *error) {
        self.session = session;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(session,face, behaviour, error);
        });

    }];
    
}

- (void) submitBehaviouralDataWithCompletion:(void (^)(AMBNResult * result, NSError *error))completion{
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");
    NSArray *touchesToSubmit;
    @synchronized(self.touches) {
        touchesToSubmit = [NSArray arrayWithArray:self.touches];
        [self.touches removeAllObjects];
    }
    NSArray *accelerationsToSubmit;
    @synchronized(self.accelerations) {
        accelerationsToSubmit = [NSArray arrayWithArray:self.accelerations];
        [self.accelerations removeAllObjects];
    }
    NSArray *textEventsToSubmit;
    @synchronized(self.textEvents) {
        textEventsToSubmit = [NSArray arrayWithArray:self.textEvents];
        [self.textEvents removeAllObjects];
    }

    [self.server submitTouches:touchesToSubmit accelerations:accelerationsToSubmit textEvents: textEventsToSubmit session:self.session completion:^(AMBNResult *result, NSError *error) {
        
        if (error){
            @synchronized(self.touches) {
                [self.touches addObjectsFromArray:touchesToSubmit];
            }
            @synchronized(self.accelerations) {
                [self.accelerations addObjectsFromArray:accelerationsToSubmit];
            }
        }else{
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

- (void) getScoreWithCompletion:(void (^)(AMBNResult * result, NSError *error))completion{
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");
    [self.server getScoreForSession:self.session completion:completion];
}

- (void) registerView:(UIView *) view withId:(NSString *) identifier{
    [self.registeredViews setObject:identifier forKey:view];
}

- (void) addSensitiveViews:(NSArray *)views{
    for (UIView *view in views){
        [self.sensitiveViews addObject:view];
    }
}

- (void) setSensitiveSalt:(NSData *)salt{
    NSString *error = [NSString stringWithFormat:@"Salt data length must be %i bits",AMBNManagerSensitiveSaltLength];
    NSAssert(salt.length == AMBNManagerSensitiveSaltLength, error);
    self.textInputCollector.sensitiveSalt = salt;
    self.touchCollector.sensitiveSalt = salt;
}


- (NSData *)generateRandomSensitiveSalt{

    NSMutableData * data = [NSMutableData dataWithLength:128];
    SecRandomCopyBytes(kSecRandomDefault, AMBNManagerSensitiveSaltLength, data.mutableBytes);
    return data;
}


- (AMBNPrivacyGuard *) disableCapturingForAllViews {
    AMBNPrivacyGuard * guard = [[AMBNPrivacyGuard alloc] initWithAllViews];
    [self.privacyGuards addObject:guard];
    return guard;   
}

- (AMBNPrivacyGuard *) disableCapturingForViews:(NSArray *) views {
    AMBNPrivacyGuard * guard = [[AMBNPrivacyGuard alloc] initWithViews:views];
    [self.privacyGuards addObject:guard];
    return guard;
}

- (BOOL) isViewIgnored: (UIView *) view{
    for(AMBNPrivacyGuard * guard in [self.privacyGuards setRepresentation]){
        if ( [guard isViewIgnored:view]){
            return true;
        }
    }
    return false;
}

- (BOOL) isViewSensitive: (UIView *) view{
    for(UIView * sensitiveView in self.sensitiveViews){
        if ([view isDescendantOfView:sensitiveView]){
            return true;
        }
    }
    return false;
}

-(BOOL) touchCollector: (id) touchCollector shouldTreatAsSenitive: (UIView *) view{
    return [self isViewSensitive:view];
}

- (void) textInputCollector:(id)textInputCollector didCollectTextInput:(AMBNTextEvent *)textEvent{
    [self.accelerometerCollector trigger];
}

- (BOOL) textInputCollector: (id) textInputCollector shouldTreatAsSenitive: (UIView *) view{
    return [self isViewSensitive:view];
}

-(BOOL)textInputCollector:(id)textInputCollector shouldIngoreEventForView:(UIView *)view{
    return [self isViewIgnored:view];
}

- (void)touchCollector:(id)touchCollector didCollectedTouch:(AMBNTouch *)touch{
    [self.accelerometerCollector trigger];
}

-(BOOL)touchCollector:(id)touchCollector shouldIgnoreTouchForView:(UIView *)view{
    return [self isViewIgnored:view];
}
- (void) enrollFaceImages:(NSArray *)images completion:(void (^)(BOOL, NSNumber *, NSError *))completion{
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");
    
    [self.server enrollFaceImages:[self adaptImages:images] session:self.session completion:^(BOOL success, NSNumber *imagesCount, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, imagesCount, error);
        });
    }];
}
- (void) authenticateFaceImages:(NSArray *)images completion: (void (^)(NSNumber * result, NSNumber * liveliness, NSError * error))completion{
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    NSAssert(self.session != nil, @"Session is not obtained");

    [self.server authFaceImages:[self adaptImages:images] session:self.session completion:^(NSNumber *result, NSNumber *liveliness, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, liveliness, error);
        });
    }];
}

- (void) compareFaceImages:(NSArray *) firstFaceImages toFaceImages:(NSArray *) secondFaceImages completion: (void (^)(NSNumber * result, NSNumber * firstLiveliness, NSNumber * secondLiveliness, NSError * error))completion{
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    
    [self.server compareFaceImages:[self adaptImages:firstFaceImages] withFaceImages:[self adaptImages:secondFaceImages] completion:^(NSNumber *similarity, NSNumber *firstLiveliness, NSNumber *secondLiveliness, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(similarity, firstLiveliness, secondLiveliness, error);
        });
    }];
}

- (void) openFaceImagesCaptureWithTopHint: (NSString *) topHint bottomHint:(NSString *) bottomHint batchSize: (NSInteger) batchSize delay: (NSTimeInterval) delay fromViewController: (UIViewController *) viewController completion: (void (^)(BOOL success, NSArray * images))completion{
    [self.faceCaptureManager openCaptureViewFromViewController:viewController topHint:topHint bottomHint:bottomHint batchSize:batchSize delay:delay completion:completion];
}

- (NSArray *) adaptImages: (NSArray *) images{
    NSMutableArray * adaptedImages = [NSMutableArray array];
    for(UIImage * image in images){
        [adaptedImages addObject:[self.imageAdapter encodedImage:image]];
    }
    return adaptedImages;
}



@end
