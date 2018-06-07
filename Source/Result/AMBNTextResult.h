//
//  AMBNTextResult.h
//  AimBrainSDK
//
//  Created by Ruslanas Kudriavcevas on 01/02/2018.
//  Copyright © 2018 Paweł Kupiec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMBNCallResult.h"

@interface AMBNTextResult : AMBNCallResult

@property(nonatomic, readonly) NSString *tokenText;

- (instancetype)initWithTokenText:(NSString *)text metadata:(NSData *)metadata;

@end

