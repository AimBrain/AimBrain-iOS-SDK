#import <Foundation/Foundation.h>
#import "AMBNPrivacyGuard.h"
#import "AMBNTextInputCollectorDelegate.h"
#import "AMBNTouchCollectorDelegate.h"
#import "AMBNResult.h"

/*!
 @define AMBNManagerBehaviouralDataSubmittedNotification behavioural data subsmission notification
 */
#define AMBNManagerBehaviouralDataSubmittedNotification @"behaviouralDataSubmitted"



/*!
 @class AMBNManager
 @discussion AMBNManager provides centralized interface for collecting behavioural data and communicating with AimBrain API
*/
@interface AMBNManager : NSObject <AMBNTextInputCollectorDelegate, AMBNTouchCollectorDelegate>

/*!
 @discussion Behavioural data collecting state.
 */
@property (readonly) BOOL started;

/*!
 @discussion Session must be set before submitting behavioural data. Instead of setting this propery you can also obtain session using @link configureWithApplicationId:secret: @/link
 */
@property NSString * session;

/*!
 @description Use this method to get AMBNManager singleton.
 @return AMBNManager singleton.
 */
+ (instancetype) sharedInstance;

/*!
 @description Starts behavioural data collection.
 */
- (void) start;

/*!
 @description Configures AMBNManager. This method must be called before creating user session or submitting behavioural data.
 @param appId Provided application identifier.
 @param appSecret Provided application secret.
 */
- (void) configureWithApplicationId: (NSString *) appId secret: (NSString *) appSecret;

/*!
 @description Creates session key and sets session property of this class.
 @param userId user identifier.
 @param completion Called when session obtainment completes. Session is successfuly obtained if session <b> session </b> is not nil and <b> error </b> is nil.
 */
- (void) createSessionWithUserId: (NSString *) userId completion: (void (^)(NSString * session, NSError *error))completion;

/*!
 @description Submits collected behavioural data. @link session @/link property must be set before using this method.
 @param completion Called when submitting completes. Submission was successful if <b> score </b> is not nil and <b> error </b> is nil.
 */
- (void) submitBehaviouralDataWithCompletion:(void (^)(AMBNResult * result, NSError *error))completion;

/*!
 @description Gets current behavioural score.
 @param completion Called when getting score completes. Fetch was successful if <b> score </b> is not nil and <b> error </b> is nil.
 */
- (void) getScoreWithCompletion:(void (^)(AMBNResult * result, NSError *error))completion;

/*!
 @description Assigns string identifier to view. Registering views increases precision of behavioural data analysis.
 @param view Registered view.
 @param identifier identifier to be assigned.
 */

- (void) registerView:(UIView *) view withId:(NSString *) identifier;


/*!
 @description Completely disables behavioural data capturing.
 @return Capturing is disabled until @link invalidate @/link method of privacy guard is called or privacy guard is garbage collected. In order to keep capturing disabled, reference to this object must be stored.
 */
- (AMBNPrivacyGuard *) disableCapturingForAllViews;



/*!
 @description Disables behavioural data capturing for events which happened inside any of given views.
 @param views Array of views for which events will not be captured.
 @return Capturing is disabled until @link invalidate @/link method of privacy guard is called or privacy guard is garbage collected. In order to keep capturing disabled, reference to this object must be stored.
 */
- (AMBNPrivacyGuard *) disableCapturingForViews:(NSArray *) views;


/*!
 @description Behavioural data of sensitve view is submitted without absoulte position and with hashed object id. Before using this method set sensitive salt.
 @param views Array of sensitive views.
 */
- (void) addSensitiveViews:(NSArray *) views;

/*!
 @description Sets salt used for generating hashed object ids.
 @param salt 128 bit data being secure generated salt
 */
- (void) setSensitiveSalt:(NSData *)salt;

/*!
 @description Generates secure 128 bit salt
 */
- (NSData *)generateRandomSensitiveSalt;

@end
