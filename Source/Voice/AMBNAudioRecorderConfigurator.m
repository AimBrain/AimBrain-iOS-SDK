#import "AMBNAudioRecorderConfigurator.h"

#import "AMBNGlobal.h"

@interface AMBNAudioRecorderConfigurator()

@property (nonatomic, strong) NSString *outputFilePath;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSMutableDictionary *recorderSettings;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic) NSTimeInterval audioLength;

@end

#define AMBNVoiceRecordingSampleRate 22050.0    // sample rate
#define AMBNVoiceRecordingNumberOfChannels 1    // single channel is enough for voice recording
#define AMBNVoiceRecordingFileType @"caf"       // use "m4a" for AAC compression or "caf" for raw (PCM/WAV)
#define AMBNVoiceRecordingMeasurementOn 1       // 1 - enabled, 0 - disabled (automatically adjusts mic input gain and low pass filtering)

@implementation AMBNAudioRecorderConfigurator

- (AVAudioRecorder*)getConfiguredRecorderWithMaxAudioLength:(NSTimeInterval)audioLength {
    self.audioLength = audioLength;
    self.audioSession = [AVAudioSession sharedInstance];
    
    NSError *error = nil;
    [self.audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&error];
    if(error) {
        AMBN_LERR(@"audioSession: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
        return nil;
    }
    
    error = nil;
    [self.audioSession setMode:AMBNVoiceRecordingMeasurementOn ? AVAudioSessionModeMeasurement : AVAudioSessionModeDefault error:&error];
    if(error) {
        AMBN_LERR(@"audioSession: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
        return nil;
    }
    
    error = nil;
    [self.audioSession setActive:YES error:&error];
    if(error) {
        AMBN_LERR(@"audioSession: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
        return nil;
    }
    return [self getRecorder];
}

- (NSMutableDictionary*)recorderSettings {
    NSMutableDictionary *recorderSettings = [[NSMutableDictionary alloc] init];

    [recorderSettings setValue:@(kAudioFormatMPEG4AAC) forKey:AVFormatIDKey];
    [recorderSettings setValue:[NSNumber numberWithFloat:AMBNVoiceRecordingSampleRate] forKey:AVSampleRateKey];
    [recorderSettings setValue:@AMBNVoiceRecordingNumberOfChannels forKey:AVNumberOfChannelsKey];
    
    if ([AMBNVoiceRecordingFileType isEqualToString:@"caf"]) {
        // setup PCM/WAV recording
        [recorderSettings setValue:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
        [recorderSettings setValue:@16 forKey:AVLinearPCMBitDepthKey];
        [recorderSettings setValue:@NO forKey:AVLinearPCMIsBigEndianKey];
        [recorderSettings setValue:@NO forKey:AVLinearPCMIsFloatKey];
    }
    return recorderSettings;
}

- (AVAudioRecorder*)getRecorder {
    [self setupOutputDirectoryForRecorder];
    NSError *error = nil;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:self.outputFilePath] settings:[self recorderSettings] error:&error];
    if(!self.recorder) {
        AMBN_LERR(@"recorder: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
        return nil;
    }
    return self.recorder;
}

- (void)setupOutputDirectoryForRecorder {
    NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
    self.outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:AMBNVoiceRecordingFileType]];
}

- (BOOL)startRecorderWithDelegate:(id)delegate {
    [self.recorder prepareToRecord];
    [self.recorder setDelegate:delegate];
    if (!self.audioSession.isInputAvailable) {
        AMBN_LWARN(@"Audio input hardware not available");
        UIAlertView *cantRecordAlert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Audio input hardware not available"
                                                                 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [cantRecordAlert show];
        return NO;
    }
    return [self.recorder recordForDuration:self.audioLength];
}

- (BOOL)recordAudioFrom:(AMBNVoiceRecordingViewController *)recordingViewController {
    return [self startRecorderWithDelegate:recordingViewController];
}

- (void)stopRecording {
    [self.recorder stop];
}

#pragma mark - Audio Playing
- (void)startPlaying {
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.outputFilePath] error:&error];
    if(error) {
        AMBN_LERR(@"audioPlayer: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
        return;
    }
    self.audioPlayer.numberOfLoops = 0;
    [self.audioPlayer play];
}

- (void)stopPlaying {
    [self.audioPlayer stop];
}

@end
