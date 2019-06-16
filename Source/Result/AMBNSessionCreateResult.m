#import "AMBNSessionCreateResult.h"


@interface AMBNSessionCreateResult ()
@property(nonatomic, strong, readwrite) NSNumber *face;
@property(nonatomic, strong, readwrite) NSNumber *voice;
@property(nonatomic, strong, readwrite) NSNumber *behaviour;
@property(nonatomic, strong, readwrite) NSString *session;
@end

@implementation AMBNSessionCreateResult

- (instancetype)initWithFace:(NSNumber *)face voice:(NSNumber *)voice behaviour:(NSNumber *)behaviour session:(NSString *)session metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.face = face;
        self.behaviour = behaviour;
        self.session = session;
        self.voice = voice;
    }
    return self;
}

@end
