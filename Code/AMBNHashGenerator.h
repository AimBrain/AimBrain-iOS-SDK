#import <Foundation/Foundation.h>

@interface AMBNHashGenerator : NSObject

+ (NSString*) generateHashFromString:(NSString *)string salt:(NSData*)salt;
+ (NSArray*) generateHashArrayFromStringArray:(NSArray *)stringArray salt:(NSData*)salt;

@end
