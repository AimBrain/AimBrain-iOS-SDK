#import "AMBNHashGenerator.h"
#import <CommonCrypto/CommonDigest.h>

@implementation AMBNHashGenerator

+ (NSString*) generateHashFromString:(NSString *)string salt:(NSData*)salt{
    NSData * stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *data = [NSMutableData dataWithData:stringData];
    [data appendData:salt];
    
    NSMutableData *shaOut = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, shaOut.mutableBytes);
    return [self hexadecimalStringFromData:shaOut];
}

+ (NSArray*) generateHashArrayFromStringArray:(NSArray *)stringArray salt:(NSData*)salt{
    NSMutableArray * hashArray = [NSMutableArray array];
    for(NSString * string in stringArray){
        [hashArray addObject:[self generateHashFromString:string salt:salt]];
    }
    return hashArray;
}

+ (NSString *)hexadecimalStringFromData:(NSData *) data
{
    const unsigned char *dataBytes = (const unsigned char *)data.bytes;
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
    {
        [hexString appendFormat:@"%02x", (unsigned int)dataBytes[i]];
    }
    
    return [NSString stringWithString:hexString];
}

@end
