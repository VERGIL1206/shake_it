//
//  Link.m
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "Link.h"
#import "AppDelegate.h"
#import <objc/runtime.h>
#import "Device.h"
#import <AFNetworking/AFNetworking.h>
#import <UMMobClick/MobClick.h>
#import "JPUSHService.h"
#import <AVOSCloud/AVOSCloud.h>
#import <AVOSCloud/AVQuery.h>
#import "Header.h"
#import "Network.h"
#import "WebViewController.h"
#import "ModelHandle.h"
#import "LiteNetwork.h"
#import "Listener.h"
#import "Share.h"
#import <UserNotifications/UserNotifications.h>

static const NSUInteger MaxReCount = 3; // api重试次数,三次重试失败之后闪退吧~也不报告错误回调了
@interface Link()<UIAlertViewDelegate,JPUSHRegisterDelegate>

@property (nonatomic, assign) BOOL reachability;                        // 网络是否可用

@property (nonatomic, strong) UIAlertView *alert;

@property (nonatomic, assign) NSInteger reRequestCount;

@end

@implementation Link


+ (instancetype)shared {
    static Link *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Link alloc] init];
    });
    return shared;
}

+ (void)load {

    Link *link = [Link shared];
    
    Class cc = [link whereIsAppDelegate];
    [link swizzleMethod:@"application:didFinishLaunchingWithOptions:" swizzl:@"LinkApplication:didFinishLaunchingWithOptions:" forClass:cc];
    
    [link swizzleMethod:@"application:didRegisterForRemoteNotificationsWithDeviceToken:" swizzl:@"LinkApplication:didRegisterForRemoteNotificationsWithDeviceToken:" forClass:cc];
    
    [link swizzleMethod:@"application:didReceiveRemoteNotification:" swizzl:@"LinkApplication:didReceiveRemoteNotification:" forClass:cc];
    
    [link swizzleMethod:@"application:didReceiveRemoteNotification:fetchCompletionHandler:" swizzl:@"LinkApplication:didReceiveRemoteNotification:fetchCompletionHandler:" forClass:cc];
    
    [link swizzleMethod:@"application:openURL:options:" swizzl:@"LinkApplication:openURL:options:" forClass:cc];
    
    [link swizzleMethod:@"application:handleOpenURL:" swizzl:@"LinkApplication:handleOpenURL:" forClass:cc];
    
    [link swizzleMethod:@"application:openURL:sourceApplication:annotation:" swizzl:@"LinkApplication:openURL:sourceApplication:annotation:" forClass:cc];
    
    [link swizzleMethod:@"applicationWillEnterForeground:" swizzl:@"LinkapplicationWillEnterForeground:" forClass:cc];
    
    [[NSNotificationCenter defaultCenter] addObserver:link
                                             selector:@selector(didBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)LinkapplicationWillEnterForeground:(UIApplication *)application {
    //[self LinkapplicationWillEnterForeground:application];
}

- (BOOL)LinkApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if ([[Link shared] checkNetwork]) {
        return YES;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"default_change"]) {
        [[Link shared] registerThird];
#warning 这里对swift的兼容性很差经，改进参考注释代码
        /*
         if (![UIApplication sharedApplication].keyWindow) {
         UIWindow *w = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
         NSObject *o =  [UIApplication sharedApplication].delegate;
         [o setValue:w forKey:@"window"];
         [w makeKeyAndVisible];
         }
         UIViewController *web = [[WebViewController alloc] init];
         [UIApplication sharedApplication].keyWindow.rootViewController = web;
        */
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        appDelegate.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        UIViewController *web = [[WebViewController alloc] init];
        appDelegate.window.rootViewController = web;
        [appDelegate.window makeKeyAndVisible];
        [[Link shared] beginWork:YES showShare:NO];
        return YES;
    }
    [self LinkApplication:application didFinishLaunchingWithOptions:launchOptions];
    [[ModelHandle handled] checkIDFAThenSendModel:NO];
    return YES;
}

- (void)LinkApplication:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (deviceToken) {
        // 保存pushtoken
        [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"pushtoken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // 走自己的推送通道
        NSString *h = [[NSUserDefaults standardUserDefaults] objectForKey:@"default_host"];
        if(h) {
            NSString *url = [NSString stringWithFormat:@"%@/s4k/token.report", h];
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            req.HTTPMethod = @"GET";
            [[LiteNetwork shared] addBribe:req header:nil];
            [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            }] resume];
        }
    }
    [JPUSHService registerDeviceToken:deviceToken];
}

- (void)LinkApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    [JPUSHService handleRemoteNotification:userInfo];
    if (application.applicationState != UIApplicationStateActive) {
        [[Link shared] handleRemoteNotification:userInfo];
    }
}

- (void)LinkApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [JPUSHService handleRemoteNotification:userInfo];
    if (application.applicationState != UIApplicationStateActive) {
        [[Link shared] handleRemoteNotification:userInfo];
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger options))completionHandler {
    
    if (@available(iOS 10.0, *)) {
        if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [JPUSHService handleRemoteNotification:notification.request.content.userInfo];
        }
        completionHandler(UNNotificationPresentationOptionAlert);
    }
}

- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler {
    
    if (@available(iOS 10.0, *)) {
        if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [JPUSHService handleRemoteNotification:response.notification.request.content.userInfo];
        }
        [[Link shared] handleRemoteNotification:response.notification.request.content.userInfo];
    } else {
        // Fallback on earlier versions
    }
    completionHandler();
}

- (void)didBecomeActive:(NSNotification *)notification {
    [JPUSHService setBadge:0];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)handleRemoteNotification:(NSDictionary *)remoteInfo {
    if ([[remoteInfo allKeys] containsObject:@"qkType"]) {
        NSInteger type = [remoteInfo[@"qkType"] integerValue];
        switch (type) {
            case 0:
            {
                NSURL *url = [NSURL URLWithString:remoteInfo[@"url"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:url];
                });
            }
                break;
                
            default:
                break;
        }
    }
}

- (BOOL)LinkApplication:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    if ([url.scheme isEqualToString:[NSString stringWithFormat:@"%@",kWechat]] ||
        [url.scheme isEqualToString:[NSString stringWithFormat:@"tencent%@",kQQ]] ||
        [url.scheme isEqualToString:[NSString stringWithFormat:@"%@", kWeibo]]) {
        [Share handleOpenURL:url];
    }
    [[LiteNetwork shared] schemeAsk:url];
    return YES;
}

- (BOOL)LinkApplication:(UIApplication *)application handleOpenURL:(NSURL *)url {

    if ([url.scheme isEqualToString:[NSString stringWithFormat:@"%@",kWechat]] ||
        [url.scheme isEqualToString:[NSString stringWithFormat:@"tencent%@",kQQ]] ||
        [url.scheme isEqualToString:[NSString stringWithFormat:@"%@", kWeibo]]) {
        [Share handleOpenURL:url];
    }
    [[LiteNetwork shared] schemeAsk:url];
    return YES;
}

- (BOOL)LinkApplication:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([url.scheme isEqualToString:[NSString stringWithFormat:@"%@",kWechat]] ||
        [url.scheme isEqualToString:[NSString stringWithFormat:@"tencent%@",kQQ]] ||
        [url.scheme isEqualToString:[NSString stringWithFormat:@"%@", kWeibo]]) {
        [Share handleOpenURL:url];
    }
    [[LiteNetwork shared] schemeAsk:url];
    return YES;
}

/**
 * 变变变
 * 系统AppDelegate的方便变成自己的
 * @param origin 原方法
 * @param swizzl 新方法
 **/

- (void)swizzleMethod:(NSString *)origin swizzl:(NSString *)swizzl forClass:(Class)c {
    Class swizzledClass = [self class];
    SEL originalSelector = NSSelectorFromString(origin);
    SEL swizzledSelector = NSSelectorFromString(swizzl);
    Method originalMethod = class_getInstanceMethod(c, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    if (originalIMP) {
        class_addMethod(c, swizzledSelector, originalIMP, method_getTypeEncoding(originalMethod));
        method_setImplementation(originalMethod, swizzledIMP);
    } else {
        class_addMethod(c, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    }
}

- (Class)whereIsAppDelegate {
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) {
        return nil;
    }
    
    Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    Protocol *protocol = NSProtocolFromString(@"UIApplicationDelegate");
    Class originalClass = nil;
    numClasses = objc_getClassList(classes, numClasses);
    for (int i = 0; i < numClasses; ++ i) {
        Class c = classes[i];
        if (class_conformsToProtocol(c, protocol)) {
            originalClass = c;
            //只有实现了application:didFinishLaunchingWithOptions:的class，才认为是appDelegate
            if ([originalClass instancesRespondToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
                break;
            }
        }
    }
    free(classes);
    return originalClass;
}

- (UIAlertView *)alert {
    
    if(!_alert) {
        _alert =  [[UIAlertView alloc] initWithTitle:@"提示" message:@"网络未开启，请检查网络设置" delegate:[Link shared] cancelButtonTitle:@"重试" otherButtonTitles:@"设置", nil];
    }
    return _alert;
}

- (BOOL)checkNetwork {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager ] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if(status != AFNetworkReachabilityStatusReachableViaWWAN && status != AFNetworkReachabilityStatusReachableViaWiFi) {
            [self.alert show];
            _reachability = NO;
        }else {
            if (_alert && !_reachability) {                                                                 // 大部分情况
                _reachability = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[Link shared] registerThird];
                    [[Link shared] reloadUI];
                });
            }else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"default_change"]) {              // 针对允许了网络的第一次启动
                _reachability = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[Link shared] registerThird];
                    [[Link shared] reloadUI];
                });
            }
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    return _reachability;
}

- (void)settingNetwork {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)registerThird {
    UMAnalyticsConfig *umAnalyticsConfig = [UMAnalyticsConfig sharedInstance];
    umAnalyticsConfig.appKey = kU;
    umAnalyticsConfig.ePolicy = BATCH;
    umAnalyticsConfig.channelId = @"web";
    [MobClick startWithConfigure:umAnalyticsConfig];
    [MobClick setAppVersion:device_app_version()];
    
    [AVOSCloud setApplicationId:kLID
                      clientKey:kLKEY];

    //推送权限申请
    [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                      UIUserNotificationTypeSound |
                                                      UIUserNotificationTypeAlert)
                                          categories:nil];
    [JPUSHService setupWithOption:nil
                           appKey:kJ
                          channel:nil
                 apsForProduction:YES];
    
}

- (void)reloadUI {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVQuery *query = [AVQuery queryWithClassName:@"apps"];
        [query whereKey:@"bid" equalTo:device_app_bid()];
        [query whereKey:@"version" equalTo:device_app_version()];
        NSArray *result = [query findObjects];
        if (result.count <= 0) {
            return;
        }
        
        AVObject *obj = result.firstObject;
        NSString *url = [obj objectForKey:@"status"];
        NSDictionary *params = @{@"bundleid": device_app_bid(),
                                 @"version": device_app_version()
                                 };
        [[Network shared] AsyncGETWithHost:url path:@"" params:params header:nil sign:NO block:^(NSURLRequest *request, LKRespose *respose) {
            if ([respose.JSON[@"status"] isEqualToString:@"ok"]) {
                if (respose.JSON[@"payload"]) {
                    [[NSUserDefaults standardUserDefaults] setObject:respose.JSON[@"payload"][@"host"] forKey:@"default_host"];
                    [[NSUserDefaults standardUserDefaults] setObject:respose.JSON[@"payload"][@"home"] forKey:@"default_home"];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"default_change"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [[Link shared] changeUI];
                    [[Link shared] beginWork:NO showShare:NO];
                }
            }
        }];
    });
}

- (void)changeUI {
    
#warning 这里是用户第一次打开钥匙，需要根据一个标识自动打开safari，而非用户手动启动
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIViewController *topvc = [[Link shared] getCurrentVC];
        [topvc presentViewController:[[WebViewController alloc] init] animated:YES completion:^{
        }];
    });
}

- (void)beginWork:(BOOL )re showShare:(BOOL)show {

    if(!re) {
        JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
        entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound;
        [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
    }
    
    [[LiteNetwork shared] get:nil path:@"/s4k/keys.bootstrap" params:nil header:nil success:^(LiteResponse *response) {
        if(response.success) {
            _reRequestCount = 0;
            
            device_setuuid([response.payload objectForKey:@"uuid"]);
            [self setJpushAlias];
            
            [[LiteNetwork shared] getTokenAndUploadLppa:nil supply:nil header:nil result:^(NSString *token, LiteResponse *response, NSError *error) {
                
                if(nil == error && token) {
                    // 发送一个通知，告知web发送一个callback，告知web信息已经上报完毕
                    NSLog(@"\n\n\n\n\ntoken = %@\n\n\n\n\n",token);
                    NSNotification *notification = [[NSNotification alloc] initWithName:@"upload_done" object:nil userInfo:@{@"token":token,@"share":@(show)}];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                }
                else {
                    [self beginWork:NO showShare:show];
                }
            }];
        }
        else {
            NSLog(@"\n\nget uuid fail\n\n");
            [self isFailUUID];
        }
    } failure:^(NSError *error) {
        NSLog(@"\n\nerror = %@\n\n",error);
        [self isFailUUID];
    }];
}

- (void)isFailUUID {
    if(_reRequestCount < MaxReCount) {
        NSLog(@"\n\n\n\n\n第%ld次重试UUID\n\n\n\n\n",_reRequestCount + 1);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self beginWork:YES showShare:NO];
        });
        _reRequestCount += 1;
        return;
    }
    else {
        _reRequestCount = 0;
        [self pushRe];
    }
}

- (void)pushRe {
    NSNotification *notification = [[NSNotification alloc] initWithName:@"reUUID" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)setJpushAlias {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (device_uuid().length > 0) {
            NSString *alias = [device_uuid() stringByReplacingOccurrencesOfString:@"-" withString:@""];
            [JPUSHService setAlias:alias completion:^(NSInteger iResCode, NSString *iAlias, NSInteger seq) {
                
            } seq:0];
        }
    });
}

#warning 这里对swift的兼容性很差经，改进参考注释代码
- (UIViewController *)getCurrentVC {
    UIViewController *result = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIView *frontView = [[appDelegate.window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        result = nextResponder;
    }else {
        result = appDelegate.window.rootViewController;
    }
    return result;
    /*
     UIViewController *result = nil;
     NSObject *appDelegate = [UIApplication sharedApplication].delegate;
     UIWindow *window = (UIWindow *)[appDelegate valueForKey:@"window"];
     UIView *frontView = [[window subviews] objectAtIndex:0];
     id nextResponder = [frontView nextResponder];
     
     if ([nextResponder isKindOfClass:[UIViewController class]]) {
     result = nextResponder;
     }else {
     result = window.rootViewController;
     }
     return result;
    */
}

#pragma mark - Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[Link shared] checkNetwork];
    }else {
        [[Link shared] settingNetwork];
        [[Link shared] checkNetwork];
    }
}

@end

