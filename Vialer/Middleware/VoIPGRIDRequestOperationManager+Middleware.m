//
//  VoIPGRIDRequestOperationManager+Middleware.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

NSString * const MiddlewareURLDeviceRecordMutation = @"/api/apns-device/";
NSString * const MiddlewareURLIncomingCallResponse = @"/api/call-response/";
NSString * const MiddlewareResponseKeyMessageStartTime = @"message_start_time";
NSString * const MiddlewareResponseKeyAvailable = @"available";
NSString * const MiddlewareResponseKeyAvailableYES = @"True";
NSString * const MiddlewareResponseKeyAvailableNO = @"False";
NSString * const MiddlewareResponseKeyUniqueKey = @"unique_key";
NSString * const MiddlewareResponseKeySIPUserId = @"sip_user_id";
NSString * const MiddlewareResponseKeyToken = @"token";
NSString * const MiddlewareResponseKeyApp = @"app";
NSString * const MiddlewareMainBundleCFBundleVersion = @"CFBundleVersion";
NSString * const MiddlewareMainBundleCFBundleShortVersionString = @"CFBundleShortVersionString";
NSString * const MiddlewareMainBundleCFBundleIdentifier = @"CFBundleIdentifier";

#import "VoIPGRIDRequestOperationManager+Middleware.h"

@implementation VoIPGRIDRequestOperationManager (Middleware)

- (void)updateDeviceRecordWithAPNSToken:(NSString *)apnsToken sipAccount:(NSString *)sipAccount withCompletion:(void (^)(NSError *error))completion {
    //The Nullable and nonnull keywords are not enough, an empty string is also not acceptable
    NSAssert(sipAccount.length > 0, @"SIP Account was not set, could not update middleware.");
    NSAssert(apnsToken.length > 0, @"APNS Token was not provided, could not update middleware");

    NSDictionary *infoDict = [NSBundle mainBundle].infoDictionary;
    NSDictionary *params = @{
                             // user id used as primary key of the SIP account registered with the currently logged in user.
                             MiddlewareResponseKeySIPUserId: sipAccount,

                             // token used to send notifications to this device.
                             MiddlewareResponseKeyToken: apnsToken,

                             // The bundle Id of this app, to allow middleware to distinguish between apps
                             MiddlewareResponseKeyApp: [infoDict objectForKey:MiddlewareMainBundleCFBundleIdentifier],

                             // Pretty name for a device in middleware.
                             @"name": [[UIDevice currentDevice] name],

                             // The version of the OS of this phone. Useful when debugging possible issues in the future.
                             @"os_version": [NSString stringWithFormat:@"iOS %@", [UIDevice currentDevice].systemVersion],

                             // The version of this client app. Useful when debugging possible issues in the future.
                             @"client_version": [NSString stringWithFormat:@"%@ (%@)", [infoDict objectForKey:MiddlewareMainBundleCFBundleShortVersionString], [infoDict objectForKey:MiddlewareMainBundleCFBundleVersion]],

                             //Sandbox is determined by the provisioning profile used on build, not on a build configuration.
                             //So, this is not the best way of detecting a Sandbox token or not.
                             //If this turns out to be unworkable, have a look at:
                             //https://github.com/blindsightcorp/BSMobileProvision
#if SANDBOX_APNS_TOKEN
                             @"sandbox" : [NSNumber numberWithBool:YES]
#endif
                             };

    [self POST:MiddlewareURLDeviceRecordMutation parameters:params withCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error) {
        if (completion) {
            if (!error) {
                completion(nil);
            } else {
                completion(error);
            }
        }
    }];
}

- (void)deleteDeviceRecordWithAPNSToken:(NSString *)apnsToken sipAccount:(NSString *)sipAccount withCompletion:(void (^)(NSError *error))completion {
    NSDictionary *params = @{
                             // user id used as primary key of the SIP account registered with the currently logged in user.
                             MiddlewareResponseKeySIPUserId: sipAccount,

                             // token used to send notifications to this device.
                             MiddlewareResponseKeyToken: apnsToken,

                             // The bundle Id of this app, to allow middleware to distinguish between apps
                             MiddlewareResponseKeyApp: [[NSBundle mainBundle].infoDictionary objectForKey:MiddlewareMainBundleCFBundleIdentifier],
                             };

    [self DELETE:MiddlewareURLDeviceRecordMutation parameters:params withCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error) {
        if (completion) {
            if (!error) {
                completion(nil);
            } else {
                completion(error);
            }
        }
    }];
}

- (void)sentCallResponseToMiddleware:(NSDictionary *)originalPayload isAvailable:(BOOL)available withCompletion:(void (^)(NSError *error))completion {

    NSDictionary *params = @{
                             // Key that was given in the device push message as reference (required).
                             MiddlewareResponseKeyUniqueKey: originalPayload[MiddlewareResponseKeyUniqueKey],
                             // Time given in the device push message to time the roundtrip (optional).
                             MiddlewareResponseKeyMessageStartTime: originalPayload[MiddlewareResponseKeyMessageStartTime],
                             // Wether the device is available to accept the call (optional but default True).
                             MiddlewareResponseKeyAvailable: available ? MiddlewareResponseKeyAvailableYES : MiddlewareResponseKeyAvailableNO,
                             };

    [self POST:MiddlewareURLIncomingCallResponse parameters:params withCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error) {
        if (!error) {
            completion(nil);
        } else {
            completion(error);
        }
    }];
}

@end