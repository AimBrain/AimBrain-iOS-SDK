#import "AMBNFaceCaptureManager.h"
#import "AMBNCameraOverlay.h"

@interface AMBNFaceCaptureManager ()
@property UIImagePickerController * imagePickerController;
@property AMBNCameraOverlay *overlay;
@property NSMutableArray *images;
@property NSInteger batchSize;
@property NSTimeInterval delay;
@property (nonatomic, copy) void (^completion)(BOOL success, NSArray * images);
@end

@implementation AMBNFaceCaptureManager

-(id)init{
    self = [super init];
    self.images = [NSMutableArray array];
    return self;
}

- (void) openCaptureViewFromViewController:(UIViewController *) viewController topHint:(NSString*)topHint bottomHint: (NSString *) bottomHint batchSize: (NSInteger) batchSize delay: (NSTimeInterval) delay completion:(void (^)(BOOL success, NSArray * images))completion{
    self.completion = completion;
    self.delay = delay;
    self.batchSize = batchSize;
    self.images = [NSMutableArray array];
    
    self.imagePickerController = [[UIImagePickerController alloc] init];
    
    [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
    
    [self configureOverlayWithTopHint:topHint bottomHint:bottomHint];
    
    
    [self.imagePickerController setShowsCameraControls:false];
    [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
    if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]){
        [self.imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceFront];
    }else{
        [self.imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceRear];
    }

    
    self.imagePickerController.cameraOverlayView = self.overlay;
    self.imagePickerController.delegate = self;
    
    [viewController presentViewController:self.imagePickerController animated:true completion:^{
        
    }];
    
}

-(void) configureOverlayWithTopHint:(NSString *) topHint bottomHint: (NSString *) bottomHint{
    NSString * faceBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"face.bundle"];
    self.overlay = [[[NSBundle bundleWithPath:faceBundlePath] loadNibNamed:@"AMBNCameraOverlay" owner:self options:nil] objectAtIndex:0];
    self.overlay.delegate = self;
    [self.overlay setFrame:self.imagePickerController.view.frame];
    self.overlay.imagePicker = self.imagePickerController;
    [self.overlay.topHintLabel setText:topHint];
    [self.overlay.bottomHintLabel setText:bottomHint];
}
- (void) dismissCaptureView {
    
}

-(void)takePicturePressedCameraOverlay:(id)overlay{
        [self.overlay.cameraButton setEnabled:false];
        [self.overlay.activityIndicator startAnimating];
        [self.imagePickerController takePicture];

}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self.images addObject:image];
    if([self.images count] == self.batchSize){
        [self.imagePickerController dismissViewControllerAnimated:true completion:^{
            
        }];
        self.completion(true, [self cropImages:self.images]);
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
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(finalCropWidth, finalCropWidth*aspectRatio), NO, 0.0);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0,0,finalCropWidth, finalCropWidth*aspectRatio), imageRef);
    CGImageRelease(imageRef);
    
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}



@end
