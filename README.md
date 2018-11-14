#AimBrain SDK integration

## Prerequisites

* XCode 8.3.3 or higher
* Target of iOS 8 or higher

## Adding framework to Xcode project
In order to integrate the AimBrain iOS SDK it is necessary to follow next steps:

1. Download the latest release of AimBrain SDK.
2. Go to your Xcode project’s “General” settings. Drag AimBrainSDK.framework from the appropriate directory to the “Embedded Binaries” section. Make sure **Copy items if needed** is selected and click **Finish**.
3. Create a new “Run Script Phase” in your app’s target’s “Build Phases” and paste the following snippet in the script text field:
```sh
bash "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/AimBrainSDK.framework/strip-frameworks.sh"
```
This step is required to work around an [App Store submission bug](http://www.openradar.me/radar?id=6409498411401216) when archiving universal binaries.

# Starting and using SDK

## Import AimBrain

Import AimBrain at the top of your application delegate and any class that uses AimBrain SDK:

Objective-C
```Objective-C
#import <AimBrainSDK/AimBrainSDK.h>
```

Swift
```Swift
import AimBrainSDK
```

## API authentication
In order to communicate with the server, the application must be configured with a valid API Key and secret. Relevant configuration parameters should be passed to the SDK using the `AMBNManager`’s `configureWithApiKey:secret` method. Most often the best place for it is  `application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions` of app delegate.

Objective-C
```objective_c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[AMBNManager sharedInstance] configureWithApiKey:@"test" secret:@"secret"];
    return YES;
}
```

Swift
```Swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    AMBNManager.sharedInstance().configure(withApiKey: "test", secret: "secret")
    return true
}
```

# Request serialisation

AimBrain SDK can be used in two modes, by sending data to AimBrain API directly or by serialising requests and submitting the data via server side integration.

To serialise requests requiring active session `AMBNManager` has to be configured with session value.

Objective-C
```objective_c
[[AMBNManager sharedInstance] configureWithSession:@"<session value>"]
```

Swift
```Swift
AMBNManager.sharedInstance().configure(withSession:<Session value>)
```

Once session is set methods with prefix ```getSerialized...``` can be called to retrieve serialized request data.

All serialisation calls return ```AMBNSerializedRequest``` object. The request data can be accessed via ```AMBNSerializedRequest``` field ```data``` field as NSData or ```AMBNSerializedRequest``` field ```dataString``` as NSString.

Please refer to server side integration documentation for serialised data processing details.

# Request metadata

For some integration scenarios additional data may be required to be sent to server.

Such integration-defined information should be submitted by calling function overload with parameter ```metadata```.

Integration-defined information is returned from server in response field ```metadata```.

# Sessions
In order to submit data to AimBrain `AMBNManager` needs to be configured with a session. There are two ways of doing it.

## Obtaining new session
A new session can be obtained by passing `userId` to `createSession` method on `AMBNManager`. Completion callback returns result object with session token, status of Facial Module modalitiy and status of Behavioural Module modality. Status of Facial Module modality (`result.face`) can have following values:

* 0 - User not enrolled - facial authentication not available, enrollment required
* 1 - User enrolled - facial authentication available.
* 2 - Building template - enrollment done, AimBrain is building user template and no further action is required.

Status of Behavioural Module modality (`result.behaviour`) can have following  values:
* 0 - User not enrolled - behavioural authentication not available, enrollment required.
* 1 - User enrolled - behavioural authentication available.

Objective-C
```objective_c
[[AMBNManager sharedInstance] createSessionWithUserId:userId completion:^(AMBNSessionCreateResult *result, NSError *error) {
    if(result){
        //Do something after successful session creation
    }
}];
```

Swift
```Swift
AMBNManager.sharedInstance().createSession(withUserId: userId) { (result, error) in
    if result != nil {
        //Do something after successful session creation
    }
}
```

The manager is automatically configured with the obtained session ID.

## Configuring with existing session
A session can be stored and later used to configure `AMBNManager`.

Objective-C
```objective_c
[AMBNManager sharedInstance].session = storedSession
```

Swift
```Swift
AMBNManager.sharedInstance().session = storedSession
```

# Behavioural module

## Registering views
The more views have identifiers assigned, the more accurate the analysis can be made. Views can be registered using `registerView:withId` method of `AMBNManager`

Objective-C
```objective_c
- (void)viewDidLoad {
    [super viewDidLoad];

    [[AMBNManager sharedInstance] registerView:self.view withId:@"sign-in-vc"];
    [[AMBNManager sharedInstance] registerView:self.emailTextField withId:@"email-text-field"];
    [[AMBNManager sharedInstance] registerView:self.pinTextField withId:@"pin-text-field"];
    [[AMBNManager sharedInstance] registerView:self.wrongPINLabel withId:@"pin-label"];
}
```

Swift
```Swift
override func viewDidLoad() {
    super.viewDidLoad()

    AMBNManager.sharedInstance().register(self.view, withId: "sign-in-vc")
    AMBNManager.sharedInstance().register(self.emailTextField, withId: "email-text-field")
    AMBNManager.sharedInstance().register(self.pinTextField, withId: "pin-text-field")
    AMBNManager.sharedInstance().register(self.wrongPINLabel, withId: "pin-label")
}
```

## Starting collection
In order to start collecting behavioural data `start` method needs to be called on `AMBNManager`

Objective-C
```objective_c
[[AMBNManager sharedInstance] start];
```

Swift
```Swift
AMBNManager.sharedInstance().start()
```

## Set data collection memory limit

Data collection can be limited, using `memoryUsageLimit` property of the
`AMBNManager` class instance. Setting kAMBNMemoryUsageUnlimited allows unlimited meory usage. Memory usage is unlimited by default.

Objective-C
```objective_c
[[AMBNManager sharedInstance] setMemoryUsageLimit:200];
```

Swift
```Swift
AMBNManager.sharedInstance().memoryUsageLimitKB = 200
```

## Submitting behavioural data
After the manager is configured with a session, behavioural data can be submitted.

Objective-C
```objective_c
[[AMBNManager sharedInstance] submitBehaviouralDataWithCompletion:^(AMBNBehaviouralResult *result, NSError *error) {
    NSNumber * score = result.score;
    //Do something with obtained score
}];
```

Swift
```Swift
AMBNManager.sharedInstance().submitBehaviouralData { (result: AMBNBehaviouralResult?, error: Error?) in
    let score = result?.score
    //Do something with obtained score
}
```

Server responds to data submission with the current behavioural score and status.

## Serialising behavioural data API call
To get serialised behavioural submission request use

Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedSubmitBehaviouralDataWithMetadata:metadata]
```

Swift
```Swift
let request: AMBNSerializedRequest = AMBNManager.sharedInstance().getSerializedSubmitBehaviouralData(withMetadata: metadata)
```

### Periodic submission
In order to schedule periodic submission use the following snippet:

Objective-C
```objective_c
// Call this method after the session ID is obtained
- (void) startPeriodicUpdate {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0f target: self selector:@selector(submitBehaviouralData) userInfo:nil repeats:true];
}

-(void) submitBehaviouralData {
    [[AMBNManager sharedInstance] submitBehaviouralDataWithCompletion:^(AMBNBehaviouralResult *result, NSError *error) {
        NSNumber * score = result.score;
        //Do something with obtained score
    }];
}
```

Swift
```Swift
// Call this method after the session ID is obtained
func startPeriodicUpdate() {
    self.timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(submitBehaviouralData), userInfo: nil, repeats: true)
}

func submitBehaviouralData() {
    AMBNManager.sharedInstance().submitBehaviouralData { (result: AMBNBehaviouralResult?, error: Error?) in
        let score = result?.score
        //Do something with obtained score
    }
}
```

## Getting the current score
To get the current session score from the server without sending any data use `getScoreWithCompletion` method from `AMBBManager`.

Objective-C
```objective_c
[[AMBNManager sharedInstance] getScoreWithCompletion:^(AMBNBehaviouralResult *result, NSError *error) {
    // Do something with the obtained score
}]
```

Swift
```Swift
AMBNManager.sharedInstance().getScoreWithCompletionHandler { (result, error) in
    // Do something with the obtained score
}
```

## Serialising current score API call
To get serialised current score request use

Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedGetScoreWithMetadata:metadata]
```

Swift
```Swift
let request: AMBNSerializedRequest = AMBNManager.sharedInstance().getSerializedGetScore(withMetadata: metadata)
```

## Sensitive data protection
It is possible to protect sensitive data. There are two ways of doing it.

### Limiting
Sensitive view data capture limiting is achieved by calling the `addSensitiveViews:` method with an array of sensitive views. Events captured on these views do not contain absolute touch location and the view identifiers are salted using device specific random key.

### Disabling
Disabled capturing of a view means absolutely no data will be collected about user activity connected with the view. Disabling means creating a `PrivacyGuard` object. It is required to store a strong reference to this object. Garbage collection of the privacy guard means that capturing will be enabled again.

>Capturing can be disabled for selected views. Array of protected views must be passed to `disableCapturingForViews` method.

Objective-C
```objective_c
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pinPrivacyGuard = [[AMBNManager sharedInstance] disableCapturingForViews:@[self.pinTextField]];
}
```

Swift
```Swift
override func viewDidLoad() {
    super.viewDidLoad()

    self.pinPrivacyGuard = AMBNManager.sharedInstance().disableCapturing(forViews: [self.piTextField])
}
```


>Another option is to disable all views. Not data will be captured until `PrivacyGuard` is invalidated (or garbage collected)

Objective-C
```objective_c
- (void)viewDidLoad {
    [super viewDidLoad];
    self.allViewsGuard = [[AMBNManager sharedInstance] disableCapturingForAllViews];
}
```

Swift
```Swift
override func viewDidLoad() {
    super.viewDidLoad()

    self.allViewsGuard = AMBNManager.sharedInstance().disableCapturingForAllViews()
}
```

>Capturing can be re-enabled by calling `invalidate` method in the `PrivacyGuard` instance

Objective-C
```objective_c
- (void)onPinAccepted {
    [super viewDidLoad];
    [self.pinPrivacyGuard invalidate];
}
```

Swift
```Swift
override func viewDidLoad() {
    super.viewDidLoad()

    self.pinPrivacyGuard.invalidate()
}
```

# Facial module

## Requesting privacy permissions
In order to use device camera, you have to ask for privacy permissions. Keys `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` are needed for camera usage and must be added to Info.plist file of your project.
```
<key>NSCameraUsageDescription</key>
<string>$(PRODUCT_NAME) would like to use the Camera to record your face.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>$(PRODUCT_NAME) would like to get photos with your face.</string>
```

## Taking pictures of the user's face
In order to take a picture of the user's face the `openFaceImagesCaptureWithTopHint` method has to be called from the `AMBNManager`. The camera view controller is then opened and completion block is called after user takes the picture and the view is dismissed.

Objective-C
```objective_c
[[AMBNManager sharedInstance] openFaceImagesCaptureWithTopHint:@"To authenticate please face the camera directly and press 'camera' button" bottomHint:@"Position your face fully within the outline with eyes between the lines." batchSize:3 delay:0.3 fromViewController:self completion:^(BOOL success, NSArray *images) {
    ...
}];
```

Swift
```Swift
AMBNManager.sharedInstance().openFaceImagesCapture(
    withTopHint: "To authenticate please face the camera directly and press 'camera' button",
    bottomHint: "Position your face fully within the outline with eyes between the lines.",
    batchSize: 3,
    delay: 0.3,
    from: self) { (images, error) in
        ...
}
```

## Recording video of the user face
In order to record video of the user's face the `instantiateFaceRecordingViewControllerWithVideoLength` method has to be called from the `AMBNManager`. The face recording view controller is return and needs to be presented. The face recording view controller has property `delegate` of type `AMBNFaceRecordingViewControllerDelegate`. It has to be set in order to receive video recording. After recording is finished `faceRecordingViewController:recordingResult:error:` method is called on the delegate. Video file is removed after this method returns.

Objective-C
```objective_c
AMBNFaceRecordingViewController *controller = [[AMBNManager sharedInstance] instantiateFaceRecordingViewControllerWithTopHint:@"Position your face fully within the outline with eyes between the lines." bottomHint:@"Position your face fully within the outline with eyes between the linessss." videoLength:2];
controller.delegate = self;
[self presentViewController:controller animated:YES completion:nil];
```

```objective_c
-(void)faceRecordingViewController:(AMBNFaceRecordingViewController *)faceRecordingViewController recordingResult:(NSURL *)video error:(NSError *)error {
    [faceRecordingViewController dismissViewControllerAnimated:YES completion:nil];
    // ... use video
}
```

Swift
```Swift
let controller: AMBNFaceRecordingViewController = AMBNManager.sharedInstance().instantiateFaceRecordingViewController(withTopHint: "Position your face fully within the outline with eyes between the lines.",
                                                                                                                       bottomHint: "Position your face fully within the outline with eyes between the linessss.",
                                                                                                                    recordingHint: "",
                                                                                                                      videoLength: 2)
controller.delegate = self
present(controller, animated: true, completion: nil)
```

```Swift
func faceRecordingViewController(_ faceRecordingViewController: AMBNFaceRecordingViewController!, recordingResult video: URL!, error: Error!) {
    faceRecordingViewController.dismiss(animated: true, completion: nil)
    // ... use video
}
```

## Retrieving and using face token
In order to enroll or authenticate using face token you have include user voice recording in user face video and submit it to the API. Face recording must contain user reading text retrieved with `getFaceTokenWithType` method. Text retrieved with `getFaceTokenWithType` is
called `face token` in the SDK.

Objective-C
```objective_c
AMBNFaceTokenType type = AMBNFaceTokenTypeAuth;
[[AMBNManager sharedInstance] getFaceTokenWithType:type completionHandler:^(AMBNVoiceTextResult *result, NSError *error) {
    // ... result.tokenText contains face token
}];
```

Swift
```Swift
let type = AMBNFaceTokenType.auth
AMBNManager.sharedInstance().getFaceToken(with: type) { (result, error) in
    // ... result.tokenText contains face token
}
```

## Face token types
Face token retrieval method `getFaceTokenWithType` takes mandatory `type` parameter.

All possible type values are defined in the enum `AMBNFaceTokenType`:
* Tokens with type `AMBNFaceTokenTypeAuth` are used for authentication calls.
* Tokens with types `AMBNFaceTokenTypeEnroll1`, `AMBNFaceTokenTypeEnroll2`, `AMBNFaceTokenTypeEnroll3`, `AMBNFaceTokenTypeEnroll4`, `AMBNFaceTokenTypeEnroll5` are used for enrollment.

To complete enrollment face tokens must be retrieved with each value used for enrollment (`AMBNFaceTokenTypeEnrollN`). Each face token must be presented to the user, recorded and enrolled successfully.

## Serialising face token call
To get serialised face token request use

Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedGetFaceTokenWithType:type metadata:matadata];
```

Swift
```Swift
let request = AMBNManager.sharedInstance().getSerializedGetFaceToken(with: type, metadata: metadata)
```

## Recording and using video with face token
Create `AMBNFaceRecordingViewController` with token text to record video with face token audio.

Objective-C
```objective_c
NSString *tokenText = ...;
AMBNFaceRecordingViewController *controller = [[AMBNManager sharedInstance] 
                instantiateFaceRecordingViewControllerWithTopHint:@"Position your face fully within the outline with eyes between the lines." 
                                                       bottomHint:@"Position your face fully within the outline with eyes between the linessss."
                                                        tokenText:[@"Please read:\n" stringByAppendingString:tokenText]
                                                      videoLength:2];
```

Swift
```Swift
let tokenText = ...
let controller: AMBNFaceRecordingViewController = AMBNManager.sharedInstance().instantiateFaceRecordingViewController(withTopHint: "Position your face fully within the outline with eyes between the lines.",
                                                                                                                       bottomHint: "Position your face fully within the outline with eyes between the linessss.",
                                                                                                                        tokenText: "Please read:\n\(tokenText)",
                                                                                                                      videoLength: 2)
```

Recording controller delegate setup, authentication API calls and enrollment API calls are the same for recordings with and without face token.

## Authenticating with the facial module
In order to authenticate with facial module, the `authenticateFaceImages` or `authenticateFaceVideo` method has to be called from the `AMBNManager`. When using `authenticateFaceImages` an array with the images of the face has to passed as a parameter. When using `authenticateFaceVideo` an url of a video of the face has to be passed as parameter. The completion block is called with the score returned by the server, the score being between 0.0 and 1.0 and a liveliness rating, indicating if the photos or video taken were of a live person.

Objective-C
```objective_c
[[AMBNManager sharedInstance] authenticateFaceImages:images completion:^(AMBNAuthenticateResult *result, NSError *error) {
    ...
}];
```

```objective_c
[[AMBNManager sharedInstance] authenticateFaceVideo:video completion:^(AMBNAuthenticateResult *result, NSError *error) {
    ...
}];
```

Swift
```Swift
AMBNManager.sharedInstance().authenticateFaceImages(images) { (result, error) in
    ...
}
```

```Swift
AMBNManager.sharedInstance().authenticateFaceVideo(video) { (result, error) in
    ...
}
```

## Serialising facial module authentication calls
To get serialised authentication requests use

Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedAuthenticateFaceImages:images metadata:matadata];
```

```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedAuthenticateFaceVideo:video metadata:matadata];
```

Swift
```Swift
let request = AMBNManager.sharedInstance().getSerializedAuthenticateFaceImages(images, metadata: metadata)
```

```Swift
let request = AMBNManager.sharedInstance().getSerializedAuthenticateFaceVideo(video, metadata: metadata)
```

## Enrolling with the facial module
Enrolling with the facial module is done by calling the `enrollFaceImages` or `enrollFaceVideo` method from the `AMBNManager`. When using `enrollFaceImages` an array with with the images of the face has to passed as a parameter. When using `enrollFaceVideo` an url of a video of the face has to be passed as parameter. The completion block is called after the operation is finished. `result` field  `success` indicates if operation was successful, `imagesCount` indicates how many images were received, processed successfully and had a face in them.

Objective-C
```objective_c
[[AMBNManager sharedInstance] enrollFaceImages:images completion:^(AMBNEnrollFaceResult *result,  NSError *error) {
    ...
}];
```

```objective_c
[[AMBNManager sharedInstance] enrollFaceVideo:video completion:^(AMBNEnrollFaceResult *result, NSError *error) {
    ...
}];
```

Swift
```Swift
AMBNManager.sharedInstance().enrollFaceImages(images) { (result, error) in
    ...
}
```

```Swift
AMBNManager.sharedInstance().enrollFaceVideo(video) { (result, error) in
    ...
}
```

## Serialising facial module enroll calls
To get serialised face enroll requests use

Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedEnrollFaceImages:images metadata:matadata];
```

```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedEnrollFaceVideo:video metadata:matadata];
```

Swift
```Swift
let request = AMBNManager.sharedInstance().getSerializedEnrollFaceImages(images, metadata: metadata)
```

```Swift
let request = AMBNManager.sharedInstance().getSerializedEnrollFaceVideo(video, metadata: metadata)
```

## Comparing faces
Two batches of images of faces can be compared using the `compareFaceImages` method of the `AMBNManager`. The method takes an array of images of the first face and an array of images of the second face (arrays contain one or more images). The completion block is called with the result object containing similarity score and the liveliness ratings of both faces.

Objective-C
```objective_c
[[AMBNManager sharedInstance] compareFaceImages:firstFaceImages toFaceImages:secondFaceImages completion:^(AMBNCompareFaceResult *result, NSError *error) {
    ...
}];
```

Swift
```Swift
AMBNManager.sharedInstance().compareFaceImages(firstFaceImages, toFaceImages: secondFaceImages) { (result, error) in
    ...
}
```

## Serialising face compare call
To get serialised face compare request use
Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedCompareFaceImages:firstFaceImages toFaceImages:secondFaceImages metadata:matadata];
```

Swift
```Swift
let result = AMBNManager.sharedInstance().getSerializedCompareFaceImages(firstFaceImages, toFaceImages: secondFaceImages, metadata: metadata)
```

# Voice module

## Requesting privacy permissions
In order to use device microphone, you have to ask for privacy permission. Keys `NSMicrophoneUsageDescription`  is needed for microphone usage and must be added in to Info.plist file of your project.
```
<key>NSMicrophoneUsageDescription</key>
<string>$(PRODUCT_NAME) would like to use the Microphone to record your voice.</string>
```

## Retrieving voice token
In order to enroll or authenticate via voice module you have to record user voice and submit it to the API. Voice recording
must contain user voice reading text retrieved with `getVoiceTokenWithType` method. Text retrieved with `getVoiceTokenWithType` is
called `voice token` in the SDK.

Objective-C
```objective_c
AMBNVoiceTokenType type = AMBNVoiceTokenTypeAuth;
[[AMBNManager sharedInstance] getVoiceTokenWithType:type completionHandler:^(AMBNVoiceTextResult *result, NSError *error) {
    // ... result.tokenText contains voice token
}];
```

Swift
```Swift
let type = AMBNVoiceTokenType.auth
AMBNManager.sharedInstance().getVoiceToken(with: type) { (result, error) in
    // ... result.tokenText contains voice token
}
```

## Voice token types
Voice token retrieval method `getVoiceTokenWithType` takes mandatory `type` parameter.

All possible type values are defined in the enum `AMBNVoiceTokenType`:
* Tokens with type `AMBNVoiceTokenTypeAuth` are used for authentication calls.
* Tokens with types `AMBNVoiceTokenTypeEnroll1`, `AMBNVoiceTokenTypeEnroll2`, `AMBNVoiceTokenTypeEnroll3`, `AMBNVoiceTokenTypeEnroll4`, `AMBNVoiceTokenTypeEnroll5` are used for enrollment.

To complete enrollment voice tokens must be retrieved with each enroll type used for enrollment (`AMBNVoiceTokenTypeEnrollN`). Each voice token must be presented to the user, recorded and enrolled successfully.

## Serialising voice token call
To get serialised voice token request use

Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedGetVoiceTokenWithType:type metadata:matadata];
```

Swift
```Swift
let request = AMBNManager.sharedInstance().getSerializedGetVoiceToken(with: type, metadata: metadata)
```

## Recording user voice
In order to record user voice the `instantiateVoiceRecordingViewControllerWithTopHint` method has to be called from the `AMBNManager`.
The voice recording view controller is returned and needs to be presented. The voice recording view controller has property `delegate`
of type `AMBNVoiceRecordingViewControllerDelegate`. It has to be set in order to receive audio recording. After recording
is finished `voiceRecordingViewController:recordingResult:error:` method is called on the delegate. Audio file is
removed after this method returns.

Voice token retrieved with `getVoiceTokenWithType` must be passed as `recordingHint` parameter. This text will be presented
to the user with voice recording instructions.

Objective-C
```objective_c
AMBNVoiceRecordingViewController *vc = [[AMBNManager sharedInstance] instantiateVoiceRecordingViewControllerWithTopHint:hint bottomHint:bottomHint recordingHint:text audioLength:5];
vc.delegate = self;
[self.viewController presentViewController:vc animated:YES completion:nil];
```

```objective_c
- (void)voiceRecordingViewController:(AMBNVoiceRecordingViewController *)voiceRecordingViewController recordingResult:(NSURL *)audio error:(NSError *)error {
    [voiceRecordingViewController dismissViewControllerAnimated:YES completion:^{}];
    // ... use audio
}
```

Swift
```Swift
if let controller = AMBNManager.sharedInstance().instantiateVoiceRecordingViewController(withTopHint: hint, bottomHint: bottomHint, recordingHint: text, audioLength: 5) {
    controller.delegate = self
    present(controller, animated: true, completion: nil)
}
```

```Swift
func voiceRecordingViewController(_ voiceRecordingViewController: AMBNVoiceRecordingViewController!, recordingResult audio: URL!, error: Error!) {
    voiceRecordingViewController.dismiss(animated: true, completion: nil)
    // ... use audio
}
```

## Authenticating with the voice module
In order to authenticate with voice module, the `authenticateVoice` method has to be called from the `AMBNManager`. An url of recorded audio file with user voice has to be passed as parameter. The completion block is called with the score returned by the server, the score being between 0.0 and 1.0 and a liveliness rating, indicating if the voice recorded was of a live person.

Objective-C
```objective_c
[[AMBNManager sharedInstance] authenticateVoice:voice completion:^(AMBNAuthenticateResult *result, NSError *error) {
    ...
}];
```

Swift
```Swift
AMBNManager.sharedInstance().authenticateVoice(voice) { (result, error) in
    ...
}
```

## Serialising voice module authentication calls
To get serialised authentication request use:

Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedAuthenticateVoice:voice metadata:matadata];
```

Swift
```Swift
let request = AMBNManager.sharedInstance().getSerializedAuthenticateVoice(voice, metadata: metadata)
```

## Enrolling with the voice module
Enrolling with the voice module is done by calling the `enrollVoice` method from the `AMBNManager`. An url of recorded audio file with user voice has to be passed as parameter. The completion block is called after the operation is finished. `result` field `success` indicates if operation was successful, `samplesCount` indicates how many audio samples were received and processed successfully.

Objective-C
```objective_c
[[AMBNManager sharedInstance] enrollVoice:audioUrl completionHandler:^(AMBNEnrollVoiceResult *result,  NSError *error) {
    ...
}];
```

Swift
```Swift
AMBNManager.sharedInstance().enrollVoice(voice) { (result, error) in
    ...
}
```

## Serialising voice module enroll calls
To get serialised voice enroll request use:

Objective-C
```objective_c
AMBNSerializedRequest *request = [[AMBNManager sharedInstance] getSerializedAuthenticateVoice:audioUrl metadata:matadata];
```

Swift
```Swift
let request = AMBNManager.sharedInstance().getSerializedAuthenticateVoice(voice, metadata: metadata)
```
