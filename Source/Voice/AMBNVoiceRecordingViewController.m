#import "AMBNVoiceRecordingViewController.h"
#import "AMBNAudioRecorderConfigurator.h"
#import "DACircularProgressView.h"

@interface AMBNVoiceRecordingViewController ()

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *topHintLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomHintLabel;
@property (weak, nonatomic) IBOutlet UILabel *recordingHintLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIView *circularProgressViewContainer;
@property (strong, nonatomic) DACircularProgressView *circularProgressView;
@property (strong, nonatomic) AMBNAudioRecorderConfigurator *recorderConfigurator;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) NSTimeInterval secondsDisplayCount;

@end

#define kGrayColor [UIColor colorWithRed:142./255. green:142./255. blue:147./255. alpha:1.0]
#define kBlueColor [UIColor colorWithRed:0./255. green:118./255. blue:255./255. alpha:1.0]
#define kBlueTranspColor [UIColor colorWithRed:0./255. green:118./255. blue:255./255. alpha:0.12]

@implementation AMBNVoiceRecordingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupRecorder];
    self.topHintLabel.text = self.topHint;
    self.bottomHintLabel.text = self.bottomHint;
    self.recordingHintLabel.text = self.recordingHint;
    
    self.bottomHintLabel.textColor = kGrayColor;
    self.secondsDisplayCount = self.audioLength;
    self.progressView.progress = 0;
    
    self.circularProgressView = [[DACircularProgressView alloc] initWithFrame:self.circularProgressViewContainer.bounds];
    self.circularProgressView.backgroundColor = [UIColor clearColor];
    self.circularProgressView.trackTintColor = kBlueTranspColor;
    self.circularProgressView.progressTintColor = kGrayColor;
    self.circularProgressView.clockwiseProgress = YES;
    self.circularProgressView.thicknessRatio = 0.01f;
    [self.circularProgressViewContainer addSubview:self.circularProgressView];
    [self.circularProgressView setProgress:1.0f];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self isMicPermitionGranted];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
        [[NSFileManager defaultManager] removeItemAtURL:self.audioRecorder.url error:nil];
    }
    [self stopTimer];
}

- (void)setupRecorder {
    self.recorderConfigurator = [[AMBNAudioRecorderConfigurator alloc] init];
    self.audioRecorder = [self.recorderConfigurator getConfiguredRecorderWithMaxAudioLength:self.audioLength];
    if (!self.audioRecorder) {
        [self proceedWithError];
    }
}

- (BOOL)isMicPermitionGranted {
    switch ([[AVAudioSession sharedInstance] recordPermission]) {
        case AVAudioSessionRecordPermissionGranted:
            return YES;
        case AVAudioSessionRecordPermissionDenied:
        case AVAudioSessionRecordPermissionUndetermined:
            [self requestMicPermition];
            return NO;
    }
}

- (void)requestMicPermition {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Microphone access disabled. Please enable it in settings" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                [self openSettings];
            }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)openSettings {
    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)proceedWithError {
    if ([self.delegate respondsToSelector:@selector(voiceRecordingViewController: recordingResult: error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            [self.delegate voiceRecordingViewController:self recordingResult:nil error:[NSError errorWithDomain:AMBNVoiceRecordingManagerErrorDomain code:AMBNVoiceRecordingManagerMissingAudioPermissionError userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Microphone permission is not granted for %@. You can grant permission in Settings", appName]}]];
        });
    }
}

- (IBAction)recordButtonPressed:(id)sender {
    if (![self isMicPermitionGranted]) {
        return;
    }
    if ([self.recorderConfigurator recordAudioFrom:self]) {
        self.recordButton.userInteractionEnabled = NO;
        self.recordButton.selected = YES;
        [self startTimer];
        [self startAnimatingProgressBar];
    }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)aRecorder successfully:(BOOL)flag {
    if ([self.delegate respondsToSelector:@selector(voiceRecordingViewController: recordingResult: error:)]) {
        if (flag) {
            [self.delegate voiceRecordingViewController:self recordingResult:aRecorder.url error:nil];
        }
        else {
            [self.delegate voiceRecordingViewController:self recordingResult:aRecorder.url error:[NSError errorWithDomain:AMBNVoiceRecordingManagerErrorDomain code:AMBNVoiceRecordingManagerFinishedUnsuccessfully userInfo:@{NSLocalizedDescriptionKey: @"recording stopped because of an audio encoding error"}]];
        }
    }
    // play recorded file for testing only
    //[self.recorderConfigurator startPlaying];
    [[NSFileManager defaultManager] removeItemAtURL:aRecorder.url error:nil];
}

- (void)startTimer {
    if (!self.timer) {
        self.secondsDisplayCount = self.audioLength;
        [self updateBottomText];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
    }
}

- (void)stopTimer {
    self.recordButton.userInteractionEnabled = YES;
    self.recordButton.selected = NO;
    self.progressView.progress = 0;
    self.circularProgressView.progressTintColor = kGrayColor;
    self.bottomHintLabel.textColor = kGrayColor;
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)timerUpdate {
    if (--self.secondsDisplayCount >= 0) {
        [self updateBottomText];
    }
    else {
        [self stopTimer];
    }
}

- (void)updateBottomText {
    switch ((NSUInteger)self.secondsDisplayCount) {
        case 0:
            self.bottomHintLabel.text = @"Recording is complete";
            break;
        case 1:
            self.bottomHintLabel.text = [NSString stringWithFormat:@"You have %@ second left", [NSNumber numberWithInteger:self.secondsDisplayCount]];
            break;
        default:
            self.bottomHintLabel.text = [NSString stringWithFormat:@"You have %@ seconds left", [NSNumber numberWithInteger:self.secondsDisplayCount]];
    }
}

- (void)startAnimatingProgressBar {
    self.bottomHintLabel.textColor = kBlueColor;
    self.circularProgressView.progressTintColor = kBlueColor;
    [self.circularProgressView setProgress:0.0f];
    [self.circularProgressView setProgress:1.0f animated:YES initialDelay:0.1f withDuration:self.audioLength];
    
    //self.progressView.progress = 1.0;
    //[UIView animateWithDuration:self.audioLength delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
    //    [self.progressView layoutIfNeeded];
    //} completion:^(BOOL finished) {
    //}];
}

- (IBAction)closeButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(voiceRecordingViewControllerClosedByUser)]) {
        [self.delegate voiceRecordingViewControllerClosedByUser];
    }
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
