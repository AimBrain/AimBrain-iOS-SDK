#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AMBNCameraPreview.h"
#import "AMBNFaceRecordingViewController.h"

@interface AMBNCaptureSessionConfigurator : NSObject

- (AVCaptureSession *)getConfiguredSessionWithMaxVideoLength:(NSTimeInterval)videoLength sizing:(AMBNRecordingPreviewSizing)sizing andCameraPreview:(AMBNCameraPreview *)cameraPreview  shouldRecordAudio:(BOOL)recordAudio;
- (void)recordVideoFrom:(AMBNFaceRecordingViewController *)recordingViewController;
- (void)stopVideoRecording;

@end
