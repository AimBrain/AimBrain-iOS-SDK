#import "AMBNVoiceRecordingManager.h"
#import <AVFoundation/AVFoundation.h>
#import "AMBNVoiceRecordingViewController.h"

@interface AMBNVoiceRecordingManager ()

@end

@implementation AMBNVoiceRecordingManager

- (id)init {
    self = [super init];
    return self;
}

- (AMBNVoiceRecordingViewController *)instantiateVoiceRecordingViewControllerWithTopHint:(NSString*)topHint bottomHint:(NSString *)bottomHint recordingHint:(NSString *)recordingHint audioLength:(NSTimeInterval)audioLength {
    NSString *voiceBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"voice.bundle"];
    AMBNVoiceRecordingViewController *voiceRecordingViewController = [[AMBNVoiceRecordingViewController alloc] initWithNibName:@"AMBNVoiceRecordingViewController" bundle:[NSBundle bundleWithPath:voiceBundlePath]];
    voiceRecordingViewController.topHint = topHint;
    voiceRecordingViewController.bottomHint = bottomHint;
    voiceRecordingViewController.audioLength = audioLength;
    voiceRecordingViewController.recordingHint = recordingHint;
    return voiceRecordingViewController;
}

- (AMBNVoiceRecordingViewController *)instantiateVoiceRecordingViewControllerWithAudioLength:(NSTimeInterval)audioLength {
    NSString *voiceBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"voice.bundle"];
    AMBNVoiceRecordingViewController *voiceRecordingViewController = [[AMBNVoiceRecordingViewController alloc] initWithNibName:@"AMBNVoiceRecordingViewController" bundle:[NSBundle bundleWithPath:voiceBundlePath]];
    voiceRecordingViewController.audioLength = audioLength;
    return voiceRecordingViewController;
}

@end
