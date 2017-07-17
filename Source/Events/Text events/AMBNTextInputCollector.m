#import "AMBNTextInputCollector.h"
#import "AMBNTextEvent.h"
#import "AMBNHashGenerator.h"
#import "AMBNEventBuffer.h"

#import "AMBNGlobal.h"


@interface AMBNTextInputCollector () {
    
    EventCollectorBlock _eventCollectedBlock;
}

@property AMBNEventBuffer * buffer;
@property AMBNViewIdChainExtractor * idExtractor;
@end


@implementation AMBNTextInputCollector

-(instancetype)initWithBuffer:(AMBNEventBuffer *)buffer idExtractor:(AMBNViewIdChainExtractor *)idExtractor eventCollected:(EventCollectorBlock)eventCollectedBlock {
    self = [super init];
    self.buffer = buffer;
    self.idExtractor = idExtractor;
    _eventCollectedBlock = eventCollectedBlock;
    return self;
}

-(void)start{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChange:) name:UITextViewTextDidChangeNotification object:nil];
}

-(void) stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)textFieldDidChange:(NSNotification*) notification{
    UITextField * textField = (UITextField *)notification.object;
    if (textField == nil){
        return;
    }
    if(self.delegate && [self.delegate textInputCollector:self shouldIngoreEventForView:textField]){
        return;
    }
    @synchronized(self.buffer) {
        AMBNTextEvent *event = [self textEventWithText:textField.text view:textField];
        
        if([self.delegate textInputCollector:self shouldTreatAsSenitive:textField]){
            event.identifiers = [AMBNHashGenerator generateHashArrayFromStringArray:event.identifiers salt:self.sensitiveSalt];
        }
        [self.buffer addObject:event];
        [self.delegate textInputCollector:self didCollectTextInput:event];
    }
    if (_eventCollectedBlock) {
        _eventCollectedBlock();
    }
}

-(void)textViewDidChange:(NSNotification*) notification{
    UITextView * textView = (UITextView *)notification.object;
    if (textView == nil){
        return;
    }
    if(self.delegate && [self.delegate textInputCollector:self shouldIngoreEventForView:textView]){
        return;
    }
    @synchronized(self.buffer) {
        AMBNTextEvent *event = [self textEventWithText:textView.text view:textView];
        
        if([self.delegate textInputCollector:self shouldTreatAsSenitive:textView]){
            event.identifiers = [AMBNHashGenerator generateHashArrayFromStringArray:event.identifiers salt:self.sensitiveSalt];
        }
        [self.buffer addObject: event];
        [self.delegate textInputCollector:self didCollectTextInput:event];
    }
    if (_eventCollectedBlock) {
        _eventCollectedBlock();
    }
}

- (AMBNTextEvent*) textEventWithText: (NSString *) text view: (UIView *) view{
    NSTimeInterval timestamp = [[NSProcessInfo processInfo] systemUptime];
    int t = round(timestamp * 1000);
    if(!text){
        text = @"";
    }
    AMBNTextEvent * event = [[AMBNTextEvent alloc] initWithText:text timestamp:t identifiers:[self.idExtractor identifierChainForView:view]];
    
    return event;
}


@end
