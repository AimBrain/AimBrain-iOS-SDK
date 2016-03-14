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
            UIView *view = [touch view];
            
            if(touch.window != [application keyWindow]){
                continue;
            }
            if(view != nil && [self.delegate touchCollector: self shouldIgnoreTouchForView: view]){
                continue;
            }
            
            AMBNTouch *createdTouch = [self createTouch: touch];
            if(createdTouch != nil){
                if([self.delegate touchCollector:self shouldTreatAsSenitive:view]){
                    createdTouch.absoluteLocation = CGPointMake(0, 0);
                    createdTouch.identifiers = [AMBNHashGenerator generateHashArrayFromStringArray:createdTouch.identifiers salt:self.sensitiveSalt];
                }
                [self.buffer addObject:createdTouch];
                [self.delegate touchCollector:self didCollectedTouch:createdTouch];
            }
            
        }
    }
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
