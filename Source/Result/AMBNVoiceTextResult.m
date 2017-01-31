//
// Created by Arunas on 10/07/16.
// Copyright (c) 2016 Paweł Kupiec. All rights reserved.
//

#import "AMBNEnrollFaceResult.h"
#import "AMBNEnrollVoiceResult.h"
#import "AMBNVoiceTextResult.h"


@interface AMBNVoiceTextResult ()
@property(nonatomic, readwrite) NSString *tokenText;
@end

@implementation AMBNVoiceTextResult

- (instancetype)initWithTokenText:(NSString *)text metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.tokenText = text;
    }
    return self;
}

@end