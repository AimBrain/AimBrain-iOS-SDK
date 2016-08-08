//
// Created by Arunas on 10/07/16.
// Copyright (c) 2016 Paweł Kupiec. All rights reserved.
//

#import "AMBNAuthenticateFaceResult.h"


@interface AMBNAuthenticateFaceResult ()
@property(nonatomic, strong, readwrite) NSNumber *score;
@property(nonatomic, strong, readwrite) NSNumber *liveliness;
@end

@implementation AMBNAuthenticateFaceResult

- (instancetype)initWithScore:(NSNumber *)score liveliness:(NSNumber *)liveliness metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.score = score;
        self.liveliness = liveliness;
    }
    return self;
}

@end