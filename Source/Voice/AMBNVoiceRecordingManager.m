#import "AMBNVoiceRecordingManager.h"
#import <AVFoundation/AVFoundation.h>
#import "AMBNVoiceRecordingViewController.h"

#import "AMBNGlobal.h"

@interface AMBNVoiceRecordingManager ()

@end

@implementation AMBNVoiceRecordingManager

- (id)init {
    self = [super init];
    return self;
}

- (AMBNVoiceRecordingViewController *)instantiateVoiceRecordingViewControllerWithTopHint:(NSString*)topHint bottomHint:(NSString *)bottomHint recordingHint:(NSString *)recordingHint audioLength:(NSTimeInterval)audioLength {
    NSString *voiceBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"voice.bundle"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:voiceBundlePath];
    AMBNVoiceRecordingViewController *voiceRecordingViewController = [[AMBNVoiceRecordingViewController alloc] initWithNibName:@"AMBNVoiceRecordingViewController" bundle:exists ? [NSBundle bundleWithPath:voiceBundlePath] : [NSBundle bundleForClass:self.classForCoder]];
    voiceRecordingViewController.topHint = topHint;
    voiceRecordingViewController.bottomHint = bottomHint;
    voiceRecordingViewController.audioLength = audioLength;
    voiceRecordingViewController.recordingHint = recordingHint;
    AMBN_LINFO(@"Voice recording controller instantiated");
    return voiceRecordingViewController;
}

- (AMBNVoiceRecordingViewController *)instantiateVoiceRecordingViewControllerWithAudioLength:(NSTimeInterval)audioLength {
    NSString *voiceBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"voice.bundle"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:voiceBundlePath];
    AMBNVoiceRecordingViewController *voiceRecordingViewController = [[AMBNVoiceRecordingViewController alloc] initWithNibName:@"AMBNVoiceRecordingViewController" bundle:exists ? [NSBundle bundleWithPath:voiceBundlePath] : [NSBundle bundleForClass:self.classForCoder]];
    voiceRecordingViewController.audioLength = audioLength;
    AMBN_LINFO(@"Voice recording controller instantiated");
    return voiceRecordingViewController;
}

@end
