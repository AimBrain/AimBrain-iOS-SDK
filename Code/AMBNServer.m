#import "AMBNServer.h"
#import <CommonCrypto/CommonCrypto.h>
#import "AMBNBehaviouralJSONComposer.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>

@implementation AMBNServer
{
    NSString *applicationId;
    NSData *applicationSecret;
    AMBNBehaviouralJSONComposer * behaviouralJSONcomposer;
    NSOperationQueue *queue;
    NSURL * sessionURL;
    NSURL * submitBehaviouralURL;
    NSURL * scoreURL;
}

- (instancetype) initWithAppId: (NSString *) appId secret: (NSString *) secret{
    self = [super init];
    queue = [[NSOperationQueue alloc] init];
    behaviouralJSONcomposer = [[AMBNBehaviouralJSONComposer alloc] init];
    
    applicationSecret = [secret dataUsingEncoding:NSUTF8StringEncoding];
    applicationId = appId;
    
    NSURL * baseURL = [NSURL URLWithString:@"https://api.aimbrain.com:443/v1/"];
    NSString * sessionPath = @"sessions";
    NSString * submitBehaviouralPath = @"behavioural";
    NSString * scorePath = @"score";
    
    sessionURL = [NSURL URLWithString:sessionPath relativeToURL:baseURL];
    submitBehaviouralURL = [NSURL URLWithString:submitBehaviouralPath relativeToURL:baseURL];
    scoreURL = [NSURL URLWithString:scorePath relativeToURL:baseURL];
    
    return self;
}

- (void) createSessionWithUserId: (NSString *)userId completion: (void (^)(NSString * session, NSError * error))completion {
    UIDevice * currentDevice = [UIDevice currentDevice];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    NSDictionary *json = @{
                           @"userId" : userId,
                           @"system" : [NSString stringWithFormat:@"iOS %@", currentDevice.systemVersion],
                           @"device" : [self machineName],
                           @"screenWidth" : [NSNumber numberWithFloat:screenRect.size.width],
                           @"screenHeight" : [NSNumber numberWithFloat:screenRect.size.height]
                           };
    
    NSMutableURLRequest *req = [self createJSONPostRequestWithJSON:json url:sessionURL];
    req.timeoutInterval = 10;
    [self sendRequest:req completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable error) {
        NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
        if(error){
            completion(nil, error);
            return;
        }
        if([httpResponse statusCode] != 200){
            completion(nil, [self composeErrorResponse:httpResponse data:data]);
            return;
        }
        
        NSError *jsonParseError;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParseError];
        if(jsonParseError || ![jsonObject isKindOfClass:[NSDictionary class]]){
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        NSString * session = [(NSDictionary *)jsonObject objectForKey:@"session"];
        if (session){
            completion(session, nil);
            return;
        }else{
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
        
    }];
}

- (void) submitTouches: (NSArray *) touches accelerations: (NSArray *) accelerations textEvents: (NSArray *) textEvents session: (NSString *) session completion: (void (^)(AMBNResult * result, NSError * error))completion {
    
    [queue addOperationWithBlock:^{
        
        id composedJSON = [behaviouralJSONcomposer composeWithTouches:touches accelerations:accelerations textEvents:textEvents session:session];
        
        NSURLRequest * req = [self createJSONPostRequestWithJSON:composedJSON url:submitBehaviouralURL];
        
        [self sendRequest:req completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable error) {
            [self handleScoreResponse:response data:data session: session error:error completion:completion];
        }];
    }];
}

- (void) getScoreForSession: (NSString *) session completion: (void (^)(AMBNResult * result, NSError * error))completion {
    
    [queue addOperationWithBlock:^{
        NSDictionary *json = @{
                               @"session" : session
                               };
        NSURLRequest * req = [self createJSONPostRequestWithJSON:json url:scoreURL];
        
        [self sendRequest:req completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable error) {
            [self handleScoreResponse:response data:data session: session error:error completion:completion];
        }];
    }];
}

- (NSError *) composeErrorResponse:(NSHTTPURLResponse *) response data: (NSData *) data{
    NSString *errorMessage;
    NSError *jsonParseError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParseError];
    if(jsonParseError){
        if ([jsonObject isKindOfClass:[NSDictionary class]]){
            errorMessage = [(NSDictionary *)jsonObject objectForKey:@"error"];
        }
    }
    NSDictionary *userInfo;
    if(errorMessage){
        userInfo = @{
                     NSLocalizedDescriptionKey : errorMessage
                     };
    }
    
    switch ([response statusCode]) {
        case 404:
            return [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerHTTPNotFoundError userInfo:userInfo];
        case 401:
            return [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerHTTPUnauthorizedError userInfo:userInfo];
        default:
            return [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerHTTPUnknownError userInfo:userInfo];
    }
    
}

- (void) handleScoreResponse: (NSURLResponse *) response data: (NSData *) data session: (NSString *) session error: (NSError *) error completion: (void (^)(AMBNResult * result, NSError * error))completion {
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    if(error){
        completion(nil, error);
        return;
    }
    if([httpResponse statusCode] != 200){
        completion(nil, [self composeErrorResponse:httpResponse data:data]);
        return;
    }else{
        NSError * jsonParseError;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParseError];
        if(jsonParseError || ![jsonObject isKindOfClass:[NSDictionary class]]){
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerWrongResponseFormatError userInfo:nil]);
            return;
        }
        
        NSNumber * score = [(NSDictionary *)jsonObject objectForKey:@"score"];
        NSNumber * status = [(NSDictionary *)jsonObject objectForKey:@"status"];
        if(score && status){
            completion([[AMBNResult alloc] initWithScore:score status:[status integerValue] session:session], nil);
            return;
        }else{
            completion(nil, [NSError errorWithDomain:AMBNServerErrorDomain code:AMBNServerMissingJSONKeyError userInfo:nil]);
            return;
        }
    }
    
}

- (void) sendRequest: (NSURLRequest *) request completionHandler:( void (^)(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError)) completion{
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:completion];
}

- (NSData *) calculateSignatureForHTTPMethod: (NSString *) httpMethod path: (NSString *) path httpBody: (NSData *) body key: (NSData *) key{
    NSData * newLineData = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSData * methodData = [[httpMethod uppercaseString] dataUsingEncoding:NSUTF8StringEncoding];
    NSData * pathData = [[path lowercaseString] dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *message = [NSMutableData dataWithData:methodData];
    [message appendData:newLineData];
    [message appendData:pathData];
    [message appendData:newLineData];
    [message appendData:body];
    NSMutableData * hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, key.bytes, key.length, message.bytes, message.length, hash.mutableBytes);
    return hash;
}

- (NSMutableURLRequest *) createJSONPostRequestWithJSON: (nonnull id) data url: (NSURL *) url{
    NSError *error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    if(error == nil){
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        [request setValue:applicationId forHTTPHeaderField:@"X-aimbrain-apikey"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSData *signatureData = [self calculateSignatureForHTTPMethod:request.HTTPMethod path:url.path httpBody:jsonData key: applicationSecret];
        NSString *singature = [signatureData base64Encoding];
        [request setValue:singature forHTTPHeaderField:@"X-aimbrain-signature"];
        
        request.HTTPBody = jsonData;
        return request;
        
    }
    return nil;
}

- (NSString *) machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}
@end
