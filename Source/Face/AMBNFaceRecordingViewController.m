#import "AMBNFaceRecordingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AMBNRecordingOverlayView.h"
#import "AMBNCameraPreview.h"
#import "AMBNCaptureSessionConfigurator.h"

@interface AMBNFaceRecordingViewController ()
@property (weak, nonatomic) IBOutlet AMBNCameraPreview *cameraPreview;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *recordingIndicator;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AMBNCaptureSessionConfigurator *sessionConfigurator;
@property AMBNRecordingOverlayView *overlayView;
@property (nonatomic) dispatch_queue_t sessionQueue;

@end

@implementation AMBNFaceRecordingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.cameraButton setEnabled:false];

    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    dispatch_async(self.sessionQueue, ^{
        [self setupCaptureSession];
    });

    [self addOverlay];
}

- (void)setupCaptureSession {
    self.sessionConfigurator = [[AMBNCaptureSessionConfigurator alloc] init];
    self.captureSession = [self.sessionConfigurator getConfiguredSessionWithMaxVideoLength:self.videoLength andCameraPreview:self.cameraPreview];
    if (self.captureSession) {
        [self.captureSession startRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cameraButton setEnabled:true];
        });
    } else {
        if ([self.delegate respondsToSelector:@selector(faceRecordingViewController: recordingResult: error:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString * appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                [self.delegate faceRecordingViewController:self recordingResult:nil error:[NSError errorWithDomain:AMBNFaceCaptureManagerErrorDomain code:AMBNFaceCaptureManagerMissingVideoPermissionError userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Camera permission is not granted for %@. You can grant permission in Settings", appName]}]];
            });
        }
    }
}
- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)viewDidDisappear:(BOOL)animated{
    dispatch_async(self.sessionQueue, ^{
        [self.captureSession stopRunning];
    });
    [super viewDidDisappear:animated];
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(faceRecordingViewController: recordingResult: error:)]) {

            if (error) {
                if ([error domain] == AVFoundationErrorDomain && [error code] == AVErrorMaximumDurationReached ) {
                    [self.delegate faceRecordingViewController:self recordingResult:outputFileURL error:nil];
                } else {
                    [self.delegate faceRecordingViewController:self recordingResult:outputFileURL error:error];
                }
            } else {
                [self.delegate faceRecordingViewController:self recordingResult:outputFileURL error:nil];
            }


        }
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
    });
    [self.recordingIndicator stopAnimating];
}

- (IBAction)recordButtonPressed:(id)sender {
    [self.cameraButton setEnabled:false];
    if(self.recordingHint){
        self.overlayView.recordingHintLabel.layer.opacity = 0;
        [self.overlayView.recordingHintLabel setHidden:NO];
        [self.overlayView.bottomHintLabel setHidden:YES];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.cameraButton.layer.opacity = 0;
        if(self.recordingHint){
            self.overlayView.recordingHintLabel.layer.opacity = 1;
        }
    } completion:^(BOOL finished) {
        [self.cameraButton setHidden:true];
    }];
    
    [self.recordingIndicator startAnimating];
    [self.sessionConfigurator recordVideoFrom:self];
}

- (void)addOverlay {
    NSString * faceBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"face.bundle"];
    self.overlayView = [[AMBNRecordingOverlayView alloc] init];
    
    NSBundle *bundle = [NSBundle bundleWithPath:faceBundlePath];
    if (bundle) {
        self.overlayView = [[[NSBundle bundleWithPath:faceBundlePath] loadNibNamed:@"AMBNRecordingOverlayView" owner:self.overlayView options:nil] firstObject];
    } else {
        self.overlayView = [[[NSBundle mainBundle] loadNibNamed:@"AMBNRecordingOverlayView" owner:self.overlayView options:nil] firstObject];
    }
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.overlayView.topHintLabel setText:self.topHint];
    [self.overlayView.bottomHintLabel setText:self.bottomHint];
    [self.overlayView.recordingHintLabel setText:self.recordingHint];
    [self.overlayView.recordingHintLabel setHidden:YES];
    [self.view addSubview:self.overlayView];
    [self addConstraints];
}

- (void)addConstraints {
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraPreview
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.overlayView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraPreview
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.overlayView
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraPreview
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.overlayView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraPreview
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.overlayView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0]];
}

@end
