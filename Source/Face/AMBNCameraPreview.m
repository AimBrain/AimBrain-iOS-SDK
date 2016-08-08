#import "AMBNCameraPreview.h"

@interface AMBNCameraPreview()

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@end

@implementation AMBNCameraPreview

- (void)layoutSubviews {
    [super layoutSubviews];
    self.captureVideoPreviewLayer.frame = self.bounds;
}

- (void)setupPreviewLayer:(AVCaptureVideoPreviewLayer *)layer {
    self.captureVideoPreviewLayer = layer;
    self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.captureVideoPreviewLayer.masksToBounds = YES;
    self.captureVideoPreviewLayer.frame = self.bounds;
    [self.layer addSublayer:self.captureVideoPreviewLayer];
}


@end