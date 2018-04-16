#import "AMBNFaceCaptureManager.h"
#import "AMBNCameraOverlay.h"
#import <AVFoundation/AVFoundation.h>
#import "AMBNImagePickerController.h"

@interface AMBNFaceCaptureManager ()
@property AMBNImagePickerController * imagePickerController;
@property AMBNCameraOverlay *overlay;
@property NSMutableArray *images;
@property NSInteger batchSize;
@property NSTimeInterval delay;
@property (nonatomic, copy) void (^completion)(NSArray * images, NSError * error);
@end

@implementation AMBNFaceCaptureManager

-(id)init{
    self = [super init];
    self.images = [NSMutableArray array];
    return self;
}

- (void) openCaptureViewFromViewController:(UIViewController *) viewController topHint:(NSString*)topHint bottomHint: (NSString *) bottomHint batchSize: (NSInteger) batchSize delay: (NSTimeInterval) delay completion:(void (^)(NSArray * images, NSError * error))completion{

    self.completion = completion;
    self.delay = delay;
    self.batchSize = batchSize;
    self.images = [NSMutableArray array];
    
    self.imagePickerController = [[AMBNImagePickerController alloc] init];
    
    [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
    [self.imagePickerController setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];

    [self configureOverlayWithTopHint:topHint bottomHint:bottomHint];
    
    [self.imagePickerController setShowsCameraControls:false];

    if([AMBNImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]){
        [self.imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceFront];
    }else{
        [self.imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceRear];
    }

    self.imagePickerController.cameraOverlayView = self.overlay;
    self.imagePickerController.delegate = self;

    [viewController presentViewController:self.imagePickerController animated:true completion:^{
        
    }];
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted == false){
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString * appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                    self.completion(nil, [NSError errorWithDomain:AMBNFaceCaptureManagerErrorDomain code:AMBNFaceCaptureManagerMissingVideoPermissionError userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Camera permission is not granted for %@. You can grant permission in Settings", appName]}]);
                    [self.imagePickerController dismissViewControllerAnimated:true completion:^{
                        
                    }];
                });
            }
        }];
    }
    
}

- (AMBNFaceRecordingViewController *)instantiateFaceRecordingViewControllerWithTopHint:(NSString*)topHint bottomHint:(NSString *)bottomHint recordingHint:(NSString *)recordingHint videoLength:(NSTimeInterval)videoLength {
    NSString * faceBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"face.bundle"];
    BOOL bundleExists = [[NSFileManager defaultManager] fileExistsAtPath:faceBundlePath];
    AMBNFaceRecordingViewController *faceRecordingViewController = [[AMBNFaceRecordingViewController alloc] initWithNibName:@"AMBNFaceRecordingViewController" bundle:bundleExists ? [NSBundle bundleWithPath:faceBundlePath] : [NSBundle bundleForClass:self.classForCoder]];
    faceRecordingViewController.topHint = topHint;
    faceRecordingViewController.bottomHint = bottomHint;
    faceRecordingViewController.videoLength = videoLength;
    faceRecordingViewController.recordingHint = recordingHint;
    return faceRecordingViewController;
}

- (AMBNFaceRecordingViewController *)instantiateFaceRecordingViewControllerWithVideoLength:(NSTimeInterval)videoLength {
    NSString * faceBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"face.bundle"];
    BOOL bundleExists = [[NSFileManager defaultManager] fileExistsAtPath:faceBundlePath];
    AMBNFaceRecordingViewController *faceRecordingViewController = [[AMBNFaceRecordingViewController alloc] initWithNibName:@"AMBNFaceRecordingViewController" bundle:bundleExists ? [NSBundle bundleWithPath:faceBundlePath] : [NSBundle bundleForClass:self.classForCoder]];
    faceRecordingViewController.videoLength = videoLength;
    return faceRecordingViewController;
}

-(void) configureOverlayWithTopHint:(NSString *) topHint bottomHint: (NSString *) bottomHint{
    NSBundle *faceBundle = [NSBundle bundleForClass:[AMBNCameraOverlay class]];
    self.overlay = [[faceBundle loadNibNamed:@"AMBNCameraOverlay" owner:self options:nil] objectAtIndex:0];
    self.overlay.delegate = self;
    [self.overlay setFrame:self.imagePickerController.cameraOverlayView.frame];
    self.overlay.imagePicker = self.imagePickerController;
    [self.overlay.topHintLabel setText:topHint];
    [self.overlay.bottomHintLabel setText:bottomHint];
}

-(void)takePicturePressedCameraOverlay:(id)overlay{
        [self.overlay.cameraButton setEnabled:false];
        [self.overlay.activityIndicator startAnimating];
        [self.imagePickerController takePicture];

}

-(void)imagePickerController:(AMBNImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self.images addObject:image];
    if([self.images count] == self.batchSize){
        [self.imagePickerController dismissViewControllerAnimated:true completion:^{
            
        }];
        self.completion([self cropImages:self.images], nil);
    }else{
        [self.imagePickerController performSelector:@selector(takePicture) withObject:nil afterDelay:self.delay];
        
    }
    
}
-(NSArray *) cropImages: (NSArray *) images{
    NSMutableArray *array = [NSMutableArray array];
    for(UIImage * image in images){
        [array addObject:[self cropImage:image]];
    }
    return array;
    
}

-(UIImage *) cropImage: (UIImage *) image{
    CGImageRef src = [image CGImage];
    CGSize size = CGSizeMake(CGImageGetWidth(src), CGImageGetHeight(src));
    CGSize rotatedSize = CGSizeMake(size.height, size.width);
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, size.height/2, size.width/2);
    CGContextRotateCTM(ctx, -M_PI_2);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(-size.width/2,-size.height/2,size.width, size.height),src);
    CGImageRef rotatedCGImage = CGBitmapContextCreateImage(ctx);
    UIGraphicsEndImageContext();
    CGFloat finalCropWidth = rotatedSize.width * 0.5 * 1.2;
    CGFloat aspectRatio = 1.5;
    CGFloat finalCropHeight = finalCropWidth * aspectRatio;
    CGRect rect = CGRectMake((rotatedSize.width - finalCropWidth) / 2,(rotatedSize.height - finalCropHeight) / 2,
                             finalCropWidth, finalCropHeight);
    
    // Create bitmap image from original image data,
    // using rectangle to specify desired crop area
    CGImageRef imageRef = CGImageCreateWithImageInRect(rotatedCGImage, rect);
    CGImageRelease(rotatedCGImage);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(finalCropWidth, finalCropWidth*aspectRatio), NO, 0.0);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0,0,finalCropWidth, finalCropWidth*aspectRatio), imageRef);
    CGImageRelease(imageRef);
    
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}



@end
