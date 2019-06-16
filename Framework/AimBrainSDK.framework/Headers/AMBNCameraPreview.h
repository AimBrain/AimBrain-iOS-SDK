#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AMBNFaceRecordingViewController.h"

@interface AMBNCameraPreview : UIView

- (void)setupPreviewLayer:(AVCaptureVideoPreviewLayer *)layer withSizing:(AMBNRecordingPreviewSizing)sizing;

@end
