#import "AMBNFaceRecordingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AMBNRecordingOverlayView.h"
#import "AMBNCameraPreview.h"
#import "AMBNCaptureSessionConfigurator.h"

static const CGFloat kPreviewAspectForFit = 288.0f / 352.0f;
static const CGFloat kButtonContainerMinHeight = 150.0f;
static const double kMaxConstraintApproximation = 0.1;

@interface AMBNFaceRecordingViewController () <AMBNRecordingDelegate>
@property (weak, nonatomic) IBOutlet AMBNCameraPreview *cameraPreview;
@property (weak, nonatomic) IBOutlet UIView *cameraButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *recordingIndicator;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerTopSpaceConstraint;
@property (strong, nonatomic) NSLayoutConstraint *previewAspectRatioConstraint;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AMBNCaptureSessionConfigurator *sessionConfigurator;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, assign) AMBNRecordingPreviewSizing previewSizing;

// custom overlay
@property UIView<AMBNRecordingOverlayDelegate,AMBNRecordingOverlayDatasource> *overlayView;
@property (nonatomic, assign) BOOL hasCustomOverlay;

@end

@implementation AMBNFaceRecordingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.cameraButton setEnabled:false];
   
    self.defaultOverlayType = AMBNDefaultOverlayTypeModernFilling;

    [self addDefaultOverlayIfNeeded];
    [self setupCustomOverlay];
    
    self.previewSizing = [self.overlayView sizingForRecordingPreview];
    
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    dispatch_async(self.sessionQueue, ^{
        [self setupCaptureSession];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGSize size = self.view.bounds.size;
    
    CGFloat previewAspect = kPreviewAspectForFit;
    if (self.previewSizing == AMBNRecordingPreviewSizingCover) {
        previewAspect = size.width / size.height;
    }
    
    if (self.previewAspectRatioConstraint == nil || ABS(self.previewAspectRatioConstraint.multiplier - previewAspect) > kMaxConstraintApproximation) {
        if (self.previewAspectRatioConstraint) {
            [self.cameraPreview removeConstraint:self.previewAspectRatioConstraint];
            self.previewAspectRatioConstraint = nil;
        }
        
        self.previewAspectRatioConstraint = [NSLayoutConstraint
                                             constraintWithItem:self.cameraPreview
                                             attribute:NSLayoutAttributeWidth
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self.cameraPreview
                                             attribute:NSLayoutAttributeHeight
                                             multiplier:previewAspect
                                             constant:0];
        
        [self.cameraPreview addConstraint:self.previewAspectRatioConstraint];
        
        CGFloat additionalButtonHeight = 0.0f;
        if (self.previewSizing == AMBNRecordingPreviewSizingCover) {
            CGFloat fitAspect = kPreviewAspectForFit;
            CGFloat fitPreviewHeight = size.width / fitAspect;
            additionalButtonHeight = MAX(size.height - fitPreviewHeight, kButtonContainerMinHeight);
        }
        self.buttonContainerTopSpaceConstraint.constant = -additionalButtonHeight;
        
        [self.view layoutIfNeeded];
    }
}

- (void)setupCaptureSession {
    self.sessionConfigurator = [[AMBNCaptureSessionConfigurator alloc] init];
    self.captureSession = [self.sessionConfigurator getConfiguredSessionWithMaxVideoLength:self.videoLength sizing:self.previewSizing andCameraPreview:self.cameraPreview shouldRecordAudio:self.recordAudio];
    if (self.captureSession) {
        [self.captureSession startRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cameraButton setEnabled:true];
            [self.overlayView recordingOverlayIsReadyToStart];
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

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
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

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isRecording) {
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
        }
        
        self.isRecording = NO;
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
    });
    
    [self.recordingIndicator stopAnimating];
}

- (IBAction)recordButtonPressed:(id)sender {
    [self.cameraButton setEnabled:false];
    if (self.isRecording == YES) {
        [self.sessionConfigurator stopVideoRecording];
        
        if ([self.delegate respondsToSelector:@selector(faceRecordingViewControllerStoppedByUser:)]) {
            [self.delegate faceRecordingViewControllerStoppedByUser:self];
        }
    } else {
        [self.recordingIndicator startAnimating];
        [self.sessionConfigurator recordVideoFrom:self];
        [self.overlayView recordingOverlayDidStartRecording];
        [self updateRecordingHintLabelWithDurationLeft:self.videoLength];
    }
    self.isRecording = !self.isRecording;
}

- (void)addDefaultOverlayIfNeeded {
    
    if (self.hasCustomOverlay) {
        return;
    }
    
    AMBNRecordingOverlayView *overlayView;
    switch (self.defaultOverlayType) {
        case AMBNDefaultOverlayTypeNone:
            return;
        case AMBNDefaultOverlayTypeModernFilling:
            overlayView = [AMBNRecordingOverlayView getWithFilledPreview];
            break;
        case AMBNDefaultOverlayTypeModernFitting:
            overlayView = [AMBNRecordingOverlayView getWithFittedPreview];
            break;
        default:
            return;
    }
    [self customizeOverlayWithView: overlayView];
}

#pragma mark - custom overlay

- (void)customizeOverlayWithView:(UIView<AMBNRecordingOverlayDelegate,AMBNRecordingOverlayDatasource> *)overlayView {
    self.hasCustomOverlay = YES;
    self.overlayView = overlayView;
    if ([self.overlayView respondsToSelector:@selector(delegate)]) {
        self.overlayView.delegate = self;
    }
}

- (void)setupCustomOverlay {
    
    if (!self.hasCustomOverlay) {
        return;
    }
    
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.overlayView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.overlayView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.overlayView
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.overlayView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.overlayView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0]];
    
    [self.overlayView recordingOverlaySetupWithTopHint:self.topHint bottomHint:self.bottomHint recordingHint:self.recordingHint];
    
    if (self.hasCustomOverlay) {
        [self.cameraButtonContainer setHidden:true];
    }
    
}

#pragma mark - AMBNRecordingDelegate

- (void)recordButtonPressed {
    [self recordButtonPressed:nil];
}

#pragma mark - helpers

- (void)updateRecordingHintLabelWithDurationLeft:(NSTimeInterval)durationLeft {
    
    id weakSelf = self;
    
    [self.overlayView recordingOverlayDidUpdateDurationLeft:durationLeft];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (durationLeft > 0) {
            NSTimeInterval nextDurationLeft = durationLeft - 1.0;
            [weakSelf updateRecordingHintLabelWithDurationLeft:nextDurationLeft];
        }
    });
}

@end
