#import "FlittMobilePlugin.h"

#import <PassKit/PassKit.h>

API_AVAILABLE(ios(11.0))
@interface FlittMobilePlugin () <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, strong) FlutterResult applePayResult;
@property (nonatomic, strong) FlutterResult applePayCompleteResult;
@property (nonatomic, strong) void (^applePayCallback)(PKPaymentAuthorizationResult *);

@end


@implementation FlittMobilePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"cloudipsp_mobile"
            binaryMessenger:[registrar messenger]];
  FlittMobilePlugin* instance = [[FlittMobilePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"supportsApplePay" isEqualToString:call.method]) {
    result(@([PKPaymentAuthorizationViewController canMakePayments]));
  } else if ([@"applePay" isEqualToString:call.method]) {
      [self applePay:call.arguments result:result];
  } else if ([@"applePayComplete" isEqualToString:call.method]) {
      [self applePayComplete:[call.arguments objectForKey:@"success"] result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)applePay:(NSDictionary *)params result:(FlutterResult)result {
    self.applePayResult = result;

    NSDictionary *config = [params objectForKey:@"config"];
    NSInteger amount = [[params objectForKey:@"amount"] intValue];
    NSString *currency = [params objectForKey:@"currency"];
    NSString *about = [params objectForKey:@"about"];

    NSDictionary* data = [config objectForKey:@"data"];
    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    paymentRequest.countryCode = @"US";
    paymentRequest.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkAmex];
    paymentRequest.merchantCapabilities = PKMerchantCapability3DS;
    paymentRequest.merchantIdentifier = [data objectForKey:@"merchantIdentifier"];
    paymentRequest.currencyCode = currency;

    NSDecimalNumber *fixedAmount = [[NSDecimalNumber alloc] initWithMantissa:amount exponent:-2 isNegative:NO];
    NSMutableArray *items = [NSMutableArray new];
    PKPaymentSummaryItem *infoItem = [PKPaymentSummaryItem summaryItemWithLabel:about amount:fixedAmount];
    [items addObject:infoItem];

    PKPaymentSummaryItem *mainItem = [PKPaymentSummaryItem summaryItemWithLabel: [config objectForKey:@"businessName"] amount:fixedAmount];
    [items addObject:mainItem];
    paymentRequest.paymentSummaryItems = items;

    dispatch_async(dispatch_get_main_queue(), ^{
        PKPaymentAuthorizationViewController *controller = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
        controller.delegate = self;
        UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [topViewController presentViewController:controller animated:YES completion:nil];
    });
}

- (UIViewController *)topViewController{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }

    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }

    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

- (void)applePayComplete:(BOOL)success result:(FlutterResult)result {
    self.applePayCompleteResult = result;
    if (self.applePayCallback) {
        if (@available(iOS 11.0, *)) {
            void (^callback)(PKPaymentAuthorizationResult *) = self.applePayCallback;
            self.applePayCallback = nil;

            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    callback([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusSuccess errors:nil]);
                } else {
                    callback([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure errors:nil]);
                }
            });
        }
    }
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    FlutterResult completeResult = self.applePayCompleteResult;
    self.applePayCompleteResult = nil;

    if (completeResult == nil) {
        FlutterResult result = self.applePayResult;
        self.applePayResult = nil;

        [controller dismissViewControllerAnimated:YES completion:^{
            // The result is already used when an unreadable token failed the sheet.
            if (result != nil) {
                result([FlutterError errorWithCode:@"UserCanceled" message:@"User canceled ApplePay authentication" details:nil]);
            }
        }];
    } else {
        [controller dismissViewControllerAnimated:YES completion:^{
            completeResult(nil);
        }];
    }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                   handler:(void (^)(PKPaymentAuthorizationResult *result))completion
API_AVAILABLE(ios(11.0))
{
    // A dictionary literal throws on a nil value, so every token field is
    // checked first. A token that cannot be read fails the sheet and reports
    // ApplePayTokenInvalid to Dart instead of terminating the app.
    NSError *jsonError;
    NSData *rawPaymentData = payment.token.paymentData;
    id paymentData = rawPaymentData.length > 0
        ? [NSJSONSerialization JSONObjectWithData:rawPaymentData options:NSJSONReadingMutableContainers error:&jsonError]
        : nil;
    NSString *displayName = payment.token.paymentMethod.displayName;
    NSString *network = payment.token.paymentMethod.network;
    NSString *transactionIdentifier = payment.token.transactionIdentifier;
    if (![paymentData isKindOfClass:[NSDictionary class]] || displayName == nil
        || network == nil || transactionIdentifier == nil) {
        FlutterResult result = self.applePayResult;
        self.applePayResult = nil;
        completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure errors:nil]);
        if (result != nil) {
            result([FlutterError errorWithCode:@"ApplePayTokenInvalid" message:@"The Apple Pay token could not be read" details:nil]);
        }
        return;
    }

    self.applePayCallback = completion;
    NSDictionary *paymentMethod = @{
                                    @"displayName":displayName,
                                    @"network":network,
                                    @"type": [FlittMobilePlugin paymentMethodName: payment.token.paymentMethod.type],
                                    };
    NSDictionary *paymentToken = @{
                                   @"paymentData": paymentData,
                                   @"paymentMethod": paymentMethod,
                                   @"transactionIdentifier": transactionIdentifier
                                   };
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setObject:paymentToken forKey:@"token"];
    if (payment.shippingContact != nil) {
        NSMutableDictionary *shipingContact = [NSMutableDictionary new];
        if (payment.shippingContact.emailAddress != nil) {
            shipingContact[@"emailAddress"] = payment.shippingContact.emailAddress;
        }
        if (payment.shippingContact.name.familyName != nil) {
            shipingContact[@"familyName"] = payment.shippingContact.name.familyName;
        }
        if (payment.shippingContact.name.givenName != nil) {
            shipingContact[@"givenName"] = payment.shippingContact.name.givenName;
        }
        if (payment.shippingContact.phoneNumber.stringValue != nil) {
            shipingContact[@"phoneNumber"] = payment.shippingContact.phoneNumber.stringValue;
        }
        [data setObject:shipingContact forKey:@"shippingContact"];
    }
    FlutterResult result = self.applePayResult;
    self.applePayResult = nil;
    if (result != nil) {
        result(data);
    }
}

+ (NSString *)paymentMethodName:(PKPaymentMethodType)type API_AVAILABLE(ios(9.0)){
    switch (type) {
        case PKPaymentMethodTypeDebit:
            return @"debit";
        case PKPaymentMethodTypeCredit:
            return @"credit";
        case PKPaymentMethodTypePrepaid:
            return @"prepaid";
        case PKPaymentMethodTypeStore:
            return @"store";
        default:
            return @"unknown";
    }
}

@end
