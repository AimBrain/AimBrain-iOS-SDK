#import <UIKit/UIKit.h>
#import "AMBNRecordingOverlay.h"

@interface AMBNRecordingOverlayView : UIView <AMBNRecordingOverlayDelegate, AMBNRecordingOverlayDatasource>

@property (nonatomic, assign) id<AMBNRecordingDelegate>delegate;

// Helpers
+ (instancetype)getWithFittedPreview;
+ (instancetype)getWithFilledPreview;

@end
