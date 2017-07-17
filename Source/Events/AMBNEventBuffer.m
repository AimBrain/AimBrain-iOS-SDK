
#import "AMBNEventBuffer.h"
#import "AMBNBaseEvent.h"
#import "AMBNTimeTools.h"


@interface AMBNEventBuffer ()

@property (readwrite) NSMutableArray<AMBNBaseEvent *> *buffer;
@property (readwrite) NSInteger bufferSizeInBytes;
@property (readwrite) NSInteger eventSizeInBytes;

// Private
- (NSInteger)countEventsBeforeTimestamp:(NSTimeInterval)timestamp;
- (NSInteger)sizeOfOldestEvents:(NSInteger)count;
- (void)removeOldestObjects:(NSInteger)count;

@end


@implementation AMBNEventBuffer

- (instancetype)initWithEventSize:(NSInteger)size {
    
    self = [super init];
    if (self) {
        _buffer = [NSMutableArray array];
        _eventSizeInBytes = size;
        _bufferSizeInBytes = 0;
    }
    
    return self;
}

- (void)addObject:(id)object {
    
    [_buffer addObject:object];
    _bufferSizeInBytes += [self sizeOfEventsInRange:NSMakeRange(_buffer.count - 1, 1)];
}

- (void)removeAllObjects {
    
    [_buffer removeAllObjects];
    _bufferSizeInBytes = 0;
}

- (void)addObjectsFromArray:(NSArray *)array {
    
    NSRange range = NSMakeRange(0, [array count]);
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];
    [_buffer insertObjects:array atIndexes:indexes];
    _bufferSizeInBytes += [self sizeOfEventsInRange:range];
}

- (NSArray *)bufferCopy {
    
    return [NSArray arrayWithArray:_buffer];
}

- (NSTimeInterval)oldestObjectTimestamp {
    
    if ([_buffer count] == 0) {
        // If there is no objects in buffer, return current uptime
        return [AMBNTimeTools systemUpTimeInMilliseconds];
    }
    
    return [[_buffer firstObject] timestamp];
}

- (NSInteger)clearObjectsOlderThanTimestamp:(NSTimeInterval)timestamp {
    
    NSInteger countToClear = [self countEventsBeforeTimestamp:timestamp];
    [self removeOldestObjects:countToClear];
    return [self sizeOfOldestEvents:countToClear];
}

- (NSInteger)sizeOfEventsInRange:(NSRange)range {
    
    NSArray *subarray = [_buffer subarrayWithRange:range];
    return subarray.count * _eventSizeInBytes;
}

#pragma mark - private

- (NSInteger)countEventsBeforeTimestamp:(NSTimeInterval)timestamp {
    
    // Returns number of events with timestamp smaller or equal to given timestamp.
    NSInteger eventsCount = 0;
    for (AMBNBaseEvent *event in _buffer) {
        if (event.timestamp <= timestamp) {
            eventsCount++;
        } else {
            break;
        }
    }
    return eventsCount;
}

- (NSInteger)sizeOfOldestEvents:(NSInteger)count {
    
    return count * _eventSizeInBytes;
}

- (void)removeOldestObjects:(NSInteger)count {
    
    NSRange range = NSMakeRange(0, count);
    _bufferSizeInBytes -= [self sizeOfEventsInRange:range];
    [_buffer removeObjectsInRange:range];
}

@end
