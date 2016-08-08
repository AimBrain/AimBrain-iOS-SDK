#import "AMBNCaptureSessionConfigurator.h"

static int32_t const MaxFrameRate = 24;

@interface AMBNCaptureSessionConfigurator()

@property (strong, nonatomic) NSString *outputFilePath;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;

@end

@implementation AMBNCaptureSessionConfigurator

- (AVCaptureSession *)getConfiguredSessionWithMaxVideoLength:(NSTimeInterval)videoLength andCameraPreview:(AMBNCameraPreview *)cameraPreview{
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    [captureSession beginConfiguration];
    if ([self setupInputDeviceForSession:captureSession]) {
        AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        dispatch_async(dispatch_get_main_queue(), ^{
            [cameraPreview setupPreviewLayer:layer];
        });
        
        [self setPresetForCaptureSession:captureSession];
        [self setupOutputForSession:captureSession withVideoLength:videoLength];
        [captureSession commitConfiguration];
        return captureSession;
    }
    [captureSession commitConfiguration];
    return nil;
}

- (BOOL)setupInputDeviceForSession:(AVCaptureSession *)captureSession {
    AVCaptureDevice *device = [self getCamera];
    if (device) {
        NSError *error = nil;
        if([device lockForConfiguration:nil] == YES) {
            if ([device respondsToSelector:@selector(setActiveVideoMaxFrameDuration:)] && [device respondsToSelector:@selector(setActiveVideoMinFrameDuration:)]) {
                [device setActiveVideoMaxFrameDuration:CMTimeMake(1, MaxFrameRate)];
                [device setActiveVideoMinFrameDuration:CMTimeMake(1, MaxFrameRate)];
            }
            [device unlockForConfiguration];
        }
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (!error) {
            [captureSession addInput:input];
            return true;
        }
    }
    return false;
}

- (AVCaptureDevice *)getCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront)
            return device;
    }
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack)
            return device;
    }
    return nil;
}

- (void)setPresetForCaptureSession:(AVCaptureSession *)captureSession {
    if ([captureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
        captureSession.sessionPreset = AVCaptureSessionPreset352x288;
    }else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    }else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
        captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    }else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
}

- (void)setupOutputForSession:(AVCaptureSession *)captureSession withVideoLength:(NSTimeInterval)videoLength{
    self.videoFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [self setVideoLengthForVideoOutput:videoLength];
    [self setupOutputDirectoryForVideoOutput];
    [captureSession addOutput:self.videoFileOutput];
    [self setFramesPerSecondForVideoFileOutput:MaxFrameRate];
}

- (void)setVideoLengthForVideoOutput:(NSTimeInterval)videoLength {
    CMTime maxDuration = CMTimeMakeWithSeconds(videoLength, MaxFrameRate);
    [self.videoFileOutput setMaxRecordedDuration:maxDuration];
}

- (void)setupOutputDirectoryForVideoOutput {
    NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
    self.outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
}

- (void)setFramesPerSecondForVideoFileOutput:(NSInteger)framesPerSecond {
    AVCaptureConnection *connection = [self.videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection respondsToSelector:@selector(setVideoMaxFrameDuration:)] && [connection respondsToSelector:@selector(setVideoMinFrameDuration:)]) {
        [connection setVideoMaxFrameDuration:CMTimeMake(1, MaxFrameRate)];
        [connection setVideoMinFrameDuration:CMTimeMake(1, MaxFrameRate)];
    }
}

- (void)recordVideoFrom:(AMBNFaceRecordingViewController *)recordingViewController {
    [self.videoFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:self.outputFilePath] recordingDelegate:recordingViewController];
}

@end