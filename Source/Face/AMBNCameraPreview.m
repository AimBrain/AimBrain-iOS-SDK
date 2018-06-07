#import "AMBNCameraPreview.h"
#import "AMBNFaceRecordingViewController.h"

@interface AMBNCameraPreview()

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@end

@implementation AMBNCameraPreview

- (void)layoutSubviews {
    [super layoutSubviews];
    self.captureVideoPreviewLayer.frame = self.bounds;
}

- (void)setupPreviewLayer:(AVCaptureVideoPreviewLayer *)layer withSizing:(AMBNRecordingPreviewSizing)sizing {
    self.captureVideoPreviewLayer = layer;
    if (sizing == AMBNRecordingPreviewSizingFit) {
        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    if (sizing == AMBNRecordingPreviewSizingCover) {
        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    self.captureVideoPreviewLayer.masksToBounds = YES;
    self.captureVideoPreviewLayer.frame = self.bounds;
    [self.layer addSublayer:self.captureVideoPreviewLayer];
}


@end
