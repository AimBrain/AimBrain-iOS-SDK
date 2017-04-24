#import "AMBNImageAdapter.h"

@implementation AMBNImageAdapter
- (id) initWithQuality: (CGFloat) quality maxHeight: (NSInteger) maxHeight{
    self = [super init];
    self.jpegQuality = quality;
    self.maxHeight = maxHeight;
    return self;
}

- (NSString *) encodedImage:(UIImage *)image{
    if(image.size.height > self.maxHeight){
        CGSize newSize = CGSizeMake(image.size.width/image.size.height * self.maxHeight, self.maxHeight);
        image = [self resizeImage:image newSize:newSize];
    }
    if ([UIImageJPEGRepresentation(image, _jpegQuality) respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [UIImageJPEGRepresentation(image, _jpegQuality) base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    }
    return [UIImageJPEGRepresentation(image, _jpegQuality) base64Encoding];
}

- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
