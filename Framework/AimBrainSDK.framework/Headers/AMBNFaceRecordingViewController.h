#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "AMBNFaceRecordingViewControllerDelegate.h"
#import "AMBNRecordingOverlay.h"

#define AMBNFaceCaptureManagerErrorDomain @"AMBNFaceCaptureManagerErrorDomain"
#define AMBNFaceCaptureManagerMissingVideoPermissionError 1

typedef NS_ENUM(NSInteger, AMBNDefaultOverlayType) {
    AMBNDefaultOverlayTypeNone = -1,
    AMBNDefaultOverlayTypeModernFitting = 0,
    AMBNDefaultOverlayTypeModernFilling = 1,
    AMBNDefaultOverlayTypeClassicFitting = 2,
    AMBNDefaultOverlayTypeClassicFilling = 3
};

@interface AMBNFaceRecordingViewController : UIViewController <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) id <AMBNFaceRecordingViewControllerDelegate> delegate;
/*!
 @description top hint displayed on video capture view
 */
@property NSString *topHint;

/*!
 @description bottom hint displayed on video capture view
 */
@property NSString *bottomHint;

/*!
 @description bottom hint displayed while recording
 */
@property NSString *recordingHint;

/*!
 @description length of recorded video
 */
@property NSTimeInterval videoLength;

/*!
 @description record audio with video capture
 */
@property bool recordAudio;

/*!
 @description type of default preview overlay
 */
@property AMBNDefaultOverlayType defaultOverlayType;

/*!
 @description replace overlay view with custom view
 */
- (void)customizeOverlayWithView:(UIView<AMBNRecordingOverlayDelegate, AMBNRecordingOverlayDatasource> *)overlayView;

@end
