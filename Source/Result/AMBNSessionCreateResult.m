//
// Created by Arunas on 10/07/16.
// Copyright (c) 2016 Paweł Kupiec. All rights reserved.
//

#import "AMBNSessionCreateResult.h"


@interface AMBNSessionCreateResult ()
@property(nonatomic, strong, readwrite) NSNumber *face;
@property(nonatomic, strong, readwrite) NSNumber *behaviour;
@property(nonatomic, strong, readwrite) NSString *session;
@end

@implementation AMBNSessionCreateResult

- (instancetype)initWithFace:(NSNumber *)face behaviour:(NSNumber *)behaviour session:(NSString *)session metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.face = face;
        self.behaviour = behaviour;
        self.session = session;
    }
    return self;
}

@end