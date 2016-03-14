#import "AMBNManager.h"
#import "AMBNAccelerometerCollector.h"
#import "AMBNServer.h"
#import "AMBNTextInputCollector.h"
#import "AMBNCapturingApplication.h"
#import "AMBNTouchCollector.h"


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

- (void) createSessionWithUserId: (NSString *) userId completion: (void (^)(NSString * session, NSError *error))completion {
    NSAssert(self.server != nil, @"AMBNManager must be configured");
    [self.server createSessionWithUserId:userId completion:^(NSString *session, NSError *error) {
        self.session = session;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(session, error);
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


@end
