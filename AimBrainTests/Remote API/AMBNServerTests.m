
#import <XCTest/XCTest.h>

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

#import "AMBNNetworkClient.h"
#import "AMBNServer.h"
#import "AMBNSessionCreateResult.h"


@interface AMBNServerTests : XCTestCase {
    AMBNNetworkClient *mocClient;
    AMBNServer *server;
}

@end


@implementation AMBNServerTests

- (void)setUp {
    
    [super setUp];
    
    mocClient = mock([AMBNNetworkClient class]);
    server = [[AMBNServer alloc] initWithNetworkClient:mocClient];
}

- (void)tearDown {

    [super tearDown];
}

- (void)testSessionEndpoint {
    
    [server createSessionWithUserId:@"test 123" metadata:nil completion:nil];
    [verify(mocClient) createJSONPOSTWithData:anything() endpoint:@"sessions"];
}

- (void)testSessionJSONCreation {
    
    NSString *userId = @"test 123";
    
    [server createSessionWithUserId:userId metadata:nil completion:nil];
    
    HCArgumentCaptor *argument = [[HCArgumentCaptor alloc] init];
    [verify(mocClient) createJSONPOSTWithData:(id)argument endpoint:@"sessions"];
    
    assertThat([argument.value valueForKey:@"userId"], is(userId));
    
}

- (void)testSessionSomething {
    
    [verify(mocClient) sendRequest:anything() queue:anything() completionHandler:anything()];
}

@end
