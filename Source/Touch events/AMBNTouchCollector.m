#import "AMBNTouchCollector.h"
#import "AMBNTouch.h"
#import "AMBNHashGenerator.h"

@interface AMBNTouchCollector ()

@property NSMutableArray * buffer;
@property int touchIdCounter;
@property NSMapTable* touches;
@property AMBNViewIdChainExtractor* idExtractor;
@end

@implementation AMBNTouchCollector

-(instancetype)initWithBuffer: (NSMutableArray *) buffer capturingApplication: (AMBNCapturingApplication *) capturingApplication idExtractor:(AMBNViewIdChainExtractor *) idExtractor{
    self = [super init];
    
    self.buffer = buffer;
    self.touchIdCounter = 0;
    self.touches = [[NSMapTable alloc] init];
    self.idExtractor = idExtractor;
    capturingApplication.capturingDelegate = self;
    return self;
}

-(void)capturingApplication:(id)application event:(UIEvent *)event{
    if(event.type == UIEventTypeTouches) {
        for (UITouch *touch in [event allTouches]) {
            if ([self canProcessTouch:touch inApplication:application]) {
                AMBNTouch *createdTouch = [self createTouch: touch];
                if(createdTouch != nil){
                    if([self.delegate touchCollector:self shouldTreatAsSenitive:[touch view]]){
                        createdTouch.absoluteLocation = CGPointMake(0, 0);
                        createdTouch.identifiers = [self generateIdentifiersForTouch:createdTouch];
                    }
                    [self.buffer addObject:createdTouch];
                    [self.delegate touchCollector:self didCollectedTouch:createdTouch];
                }
            }
        }
    }
}

- (BOOL)canProcessTouch:(UITouch *)touch inApplication:(id)application {
    
    UIView *view = [touch view];
    
    if(touch.window != [application keyWindow]){
        return NO;
    }
    if(view != nil && [self.delegate touchCollector: self shouldIgnoreTouchForView: view]){
        return NO;
    }
    return YES;
}

- (NSArray *)generateIdentifiersForTouch:(AMBNTouch *)touch {
    
    return [AMBNHashGenerator generateHashArrayFromStringArray:touch.identifiers salt:self.sensitiveSalt];
}

- ( AMBNTouch * _Nullable ) createTouch: (UITouch *) touch{
    NSNumber *tid = [self generateTouchIdForTouch:touch];
    if(tid != nil){
        NSArray *identifiers = [self.idExtractor identifierChainForView:touch.view];
        return [[AMBNTouch alloc] initWithTouch:touch touchId:tid.intValue identifiers:identifiers];
    }else{
        return nil;
    }
}


- (NSNumber * _Nullable) generateTouchIdForTouch: (UITouch *) touch{
    switch (touch.phase) {
        case UITouchPhaseBegan:{
            NSNumber *touchId = [NSNumber numberWithInt:self.touchIdCounter++];
            [self.touches setObject:touchId forKey:touch];
            return touchId;
        }
        case UITouchPhaseCancelled:{
            NSNumber *tid = [self.touches objectForKey:touch];
            if (tid != nil){
                return tid;
            }else{
                return nil;
            }
        }
        case UITouchPhaseEnded:{
            NSNumber *tid = [self.touches objectForKey:touch];
            [self.touches removeObjectForKey:touch];
            return tid;
        }
        case UITouchPhaseMoved:
        case UITouchPhaseStationary:{
            NSNumber *tid = [self.touches objectForKey:touch];
            return tid;
        }
    }
}

@end
