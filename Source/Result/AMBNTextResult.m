//
//  AMBNTextResult.m
//  AimBrainSDK
//
//  Created by Ruslanas Kudriavcevas on 01/02/2018.
//  Copyright © 2018 Paweł Kupiec. All rights reserved.
//

#import "AMBNTextResult.h"

@interface AMBNTextResult ()
@property(nonatomic, readwrite) NSString *tokenText;
@end

@implementation AMBNTextResult

- (instancetype)initWithTokenText:(NSString *)text metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.tokenText = text;
    }
    return self;
}

@end
