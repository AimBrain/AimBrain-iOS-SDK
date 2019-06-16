@import Foundation;


typedef NS_ENUM(NSInteger, AMBNRecordingPreviewSizing) {
    AMBNRecordingPreviewSizingFit = 0,
    AMBNRecordingPreviewSizingCover = 1
};


@protocol AMBNRecordingDelegate <NSObject>

@optional

/**
 Action to initiate recording of capture session
 */
- (void)recordButtonPressed;

@end



@protocol AMBNRecordingOverlayDelegate <NSObject>

/**
 Hints to show in overlay
 */
- (void)recordingOverlaySetupWithTopHint:(NSString *)topHint bottomHint:(NSString *)bottomHint recordingHint:(NSString *)recordingHint;

/**
 Capture session is ready to start
 */
- (void)recordingOverlayIsReadyToStart;

/**
 Capture session did start recording
 */
- (void)recordingOverlayDidStartRecording;

/**
 Remaining duration did update
 */
- (void)recordingOverlayDidUpdateDurationLeft:(NSTimeInterval)durationLeft;

@end



@protocol AMBNRecordingOverlayDatasource <NSObject>

/**
 Sizing type for recording preview layer
 */
- (AMBNRecordingPreviewSizing)sizingForRecordingPreview;

@optional

/**
 Should be implemented to call recording controller's actions
 */
@property (nonatomic, assign) id<AMBNRecordingDelegate>delegate;

@end
