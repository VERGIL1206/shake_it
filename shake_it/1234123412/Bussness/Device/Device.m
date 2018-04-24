//
//  Device.m
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "Device.h"
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <AdSupport/AdSupport.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <mach-o/dyld.h>
#import <sys/stat.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>
#import <Reachability/Reachability.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "NSObject+BQLInvoker.h"
#import "Tool.h"
#import "DeviceModel.h"
#import "SSKeychain.h"

#define kUUIDKey            @"$UUID_KEY$"

@implementation Device

// 获取网络类型
NSString *device_nettype(void) {
    
    NSString *netconnType = @"";
    Reachability *reach = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    switch ([reach currentReachabilityStatus]) {
            case NotReachable: {
            netconnType = @"no network";
        }
            break;
            case ReachableViaWiFi: {
            netconnType = @"Wifi";
        }
            break;
            case ReachableViaWWAN: {

            CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
            NSString *currentStatus = info.currentRadioAccessTechnology;
            if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
                netconnType = @"GPRS";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]) {
                netconnType = @"2.75G EDGE";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]){
                netconnType = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]){
                netconnType = @"3.5G HSDPA";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]){
                netconnType = @"3.5G HSUPA";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]){
                netconnType = @"2G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]){
                netconnType = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]){
                netconnType = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]){
                netconnType = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyeHRPD"]){
                netconnType = @"HRPD";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]){
                netconnType = @"4G";
            }
        }
            break;
            
        default:
            break;
    }
    return netconnType;
}

// 获取设备型号
NSString *device_model(void) {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
}

// 获取设备ip
NSString *device_ip(void) {
    
    struct ifaddrs *interfaces = NULL;
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    NSString *empty = @"0.0.0.0";
    if (getifaddrs(&interfaces) != 0) {
        return empty;
    }
    
    while(interfaces != NULL) {
        sa_family_t sa_type = interfaces->ifa_addr->sa_family;
        if (sa_type == AF_INET || sa_type == AF_INET6) {
            NSString *name = [NSString stringWithUTF8String:interfaces->ifa_name];
            NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)interfaces->ifa_addr)->sin_addr)]; // pdp_ip0
            if ([name isEqualToString:@"en0"]) {
                wifiAddress = addr;
            } else if ([name isEqualToString:@"pdp_ip0"]) {
                cellAddress = addr;
            }
        }
        interfaces = interfaces->ifa_next;
    }
    freeifaddrs(interfaces);
    
    if (wifiAddress) {
        return wifiAddress;
    }
    if (cellAddress) {
        return cellAddress;
    }
    return empty;
}

// 获取设备idfa是否可用
BOOL device_idfaAvailable(void) {
    
    return [ASIdentifierManager sharedManager].advertisingTrackingEnabled;
}

// 获取设备idfa
NSString *device_idfa(void) {

    return [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
}

// 获取钥匙bid
NSString *device_app_bid(void) {
    
    return [[NSBundle mainBundle] bundleIdentifier];
}

// 获取钥匙版本号
NSString *device_app_version(void) {
    
    NSString *infoPath = [[NSBundle mainBundle] pathForResource:@"Info"
                                                         ofType:@"plist"];
    NSDictionary *infoDic = [[NSDictionary alloc] initWithContentsOfFile:infoPath];
    return [NSString stringWithFormat:@"%@.%@", infoDic[@"CFBundleShortVersionString"], infoDic[(__bridge NSString *)kCFBundleVersionKey]];
}

BOOL device_bad(void) {
    
    //通过检查 kernel dylib 是否被篡改来判断
    Dl_info dylib_info;
    int (*func_stat)(const char*, struct stat*) = stat;
    const char *kernel_lib = "/usr/lib/system/libsystem_kernel.dylib";
    if (dladdr(func_stat, &dylib_info)) {
        if (strncmp(dylib_info.dli_fname, kernel_lib, strlen(kernel_lib) ) != 0) {
            return YES;
        }
    }
    
    //cydia 目录
    struct stat stat_info;
    if (0 == stat("/Applications/Cydia.app", &stat_info)) {
        return YES;
    }
    
    //通过检查已经注册的所有 dylib 来匹配越狱 lib
    uint32_t count = _dyld_image_count();
    const char *this_may_be_jailbreak = "Library/MobileSubstrate/MobileSubstrate.dylib";
    for (uint32_t i = 0; i < count; ++ i) {
        const char *name = _dyld_get_image_name(i);
        if (strncmp(name, this_may_be_jailbreak, strlen(this_may_be_jailbreak)) == 0) {
            return YES;
        }
    }
    
    //通过检查环境变量来判断是否越狱，非越狱环境变量为空
    char *env = getenv("DYLD_INSERT_LIBRARIES");
    if (env != NULL) {
        return YES;
    }
    
    return NO;
}

BOOL device_bad1(void) {
    
    // 一般越狱机会安装下面几个文件，能打开就说明是越狱机
    NSArray *jailbreak_tool_paths = @[
                                      fetchBlured(@"AwECaDJC83JE1jKGCy+cSwZORRKCx6PG31S53+Mbw7fEzQ43MdikbUWHbSxKePoXNs7RmNkzIVOUJZZuwvi84Ceq5+c7/qGi3YDSa6KIcxR0NNoKcFpGWtLxT6PT3tYlUNo+OJyL5ejl5dtSVVguevmM"),
                                      fetchBlured(@"AwFgJZN/RGMICcKOw2YTvNoiPKr5jmtJdie9PlaN78TwmK91MuAwHZRaXbiSiwLRA/xAIi0lGUeFMKllZMxIj6sVbt3SFHYt436iVxVwFKD6unaVed0Qgf4dXAxmjaIvtmwS8tQQomdas96uVJXlucSiALcwxrQ4yLLORMY9swhiroy88+M5UDMlQNh/zlIavkQ="),
                                      @"/bin/bash",
                                      @"/usr/sbin/sshd",
                                      @"/etc/apt"
                                      ];
    for (int i = 0; i < jailbreak_tool_paths.count; i ++) {

        if ([[NSFileManager defaultManager] fileExistsAtPath:jailbreak_tool_paths[i]]) {
            return YES;
        }
    }
    
    // 根据是否能打开cydia://来判断
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]]) {
        return YES;
    }
    
    return NO;
}

// 获取设备mac地址，如果为nil则说明未越狱,否则就是越狱机
NSString *device_mac(void) {
    
    return @"0200000000";
}

void device_setuuid(NSString *uuid) {
    
    if(uuid) {
        [SSKeychain setPassword:uuid forService:kUUIDKey account:device_app_bid()];
    }
}

NSString *device_uuid(void) {
    
    return [SSKeychain passwordForService:kUUIDKey account:device_app_bid()] ? [SSKeychain passwordForService:kUUIDKey account:device_app_bid()]:@"";
}

// 获取设备wifi名称
NSString *device_ssid(void) {
    
    NSString *result = [SSIDInfo() isKindOfClass:[NSDictionary class]] ? SSIDInfo()[@"SSID"] : nil;
    return result ? : @"";
}

// 获取设备wifi的mac地址
NSString *device_bssid(void) {
    
    NSString *result = [SSIDInfo() isKindOfClass:[NSDictionary class]] ? SSIDInfo()[@"BSSID"] : nil;
    return result ? : @"";
}

// 获取网络制式(运营商)
NSString *device_netSys(void) {
    
    CTTelephonyNetworkInfo *info = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier = [info subscriberCellularProvider];
    
    if (!carrier.isoCountryCode) {
        return @"";
    }
    return [carrier carrierName] ? [carrier carrierName]:@"";
}

// 获取钥匙推送功能时候开启
NSInteger device_pushAvailable(void) {
    
    return [UIApplication sharedApplication].currentUserNotificationSettings.types > 0 ? 1:0;
}

BOOL device_isTargetDownloaded(NSString *bid) {
    
    NSDictionary *info = device_info(bid);
    if(info && [[info allKeys] containsObject:@"bundle_version"]) {
        
        NSString *bundle_version = [info objectForKey:@"bundle_version"];
        if(bundle_version && bundle_version.length > 0) {
            return YES;
        }
        return NO;
    }
    return NO;
}

// 获取ios11以下获取设备已安装应用列表
NSArray *device_lppa(void) {
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 11.0) {
        return @[];
    }
    else {
        id base_cls_aw = NSClassFromString(lsapp());
        id cls_aw = [base_cls_aw bql_invokeMethod:dews()];
        NSArray *cls_all = [cls_aw bql_invoke:fetchBlured(@"AwEktger6EIw/HxA33oYP1f9D6OjBmcKrQ+7sTJcgU0hU8Rcgjr/0/Z+p5//JhEghJOo3FaNI52nRrED8g2aJ4E2ByQiNIlhVe6BnTeTdK8vCKxrNyK3trA9Wl/836wRpsvRb2FW/YaP2asik1d9UJw/")];
        
        NSMutableArray *array = [NSMutableArray array];
        [cls_all enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [array addObject:[DeviceModel modelling:obj]];
        }];
        return array;
    }
}

// 获取ios11之后根据bid列表扫描已安装应用列表
NSArray *device_lppa_ios11(NSArray <NSDictionary *>*bids) {
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 11.0) {
        
        NSBundle *container = [NSBundle bundleWithPath:fetchBlured(@"AwEVp3bD5bxE7T/oec1LdyvGmQe9IHoaWZXlB+F8x3zlEh3mAx74a8Zfj/fwlzOMBG3AjZ5IxI9jaazZm1RJBW4n7B+r1JTabOZ/xryng7C09DDGVzdqWbga6r6X1piLRIHCk/33ON5J1aAJgTAD5z9oQ454RJ7dTyxlyZ/5iSFCtcFZrMDBTBYNldcKyNwryslX+L5BkvTz59N9ZYKOl8/K")];
        
        if ([container load]) {
            
            id appContainer = NSClassFromString(fetchBlured(@"AwHGdbXRWUQdGUxmHtlkqC141uMsc6SCs0yHR10R28O4yDRlaoEmqvgj2pgy7KfKllrL6i716Nw8+dFiP7hIudIkKHWBnN/08mQuKKsENCRIK8X2oMsx4p7eaI/rYtbro74="));
            
            NSMutableArray *array = [NSMutableArray array];
            [bids enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSString *bid = @"";
                if(obj.allKeys.count > 1 && [obj.allKeys containsObject:@"bundle_id"]) {
                    bid = [obj objectForKey:@"bundle_id"];
                }
                SEL sel = NSSelectorFromString(cwierr());
                if ([appContainer respondsToSelector:sel]) {
                    id app = [appContainer bql_invokeMethod:cwierr() arguments:@[bid]];
                    //id app = [appContainer performSelector:@selector(containerWithIdentifier:error:) withObject:bid withObject:nil];
                    if(app) {
                        [array addObject:obj];
                    }
                }
            }];
            return array;
        }
        else {
            return @[];
        }
    }
    else {
        return device_lppa();
    }
}

NSDictionary *device_info(NSString *bid) {
    
    if(!bid) return @{};
    id app = nil;
    id proxy = NSClassFromString(fetchBlured(@"AwGHGf0O/cfWGjFC2dTgIKNgcowpPDPC7IpbWHV0yLao3GGFHyHhqTQpfZn3Lp4k8lVUEksb7+FwJfLKOm7pJenZILoo1MxEOXMWJ74CEVn0U3f2Yp2wBWD1qzsBVU+WMlI="));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL sel = NSSelectorFromString(apid());
    if ([proxy respondsToSelector:sel]) {
        app = [proxy bql_invokeMethod:apid() arguments:@[bid]];
        return [DeviceModel modelling:app];
    }
#pragma clang diagnostic pop
    return @{};
}


NSString *device_token() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id data = [defaults objectForKey:@"pushtoken"];
    if(data) {
        return [NSString stringWithFormat:@"%@",data];
    }
    return nil;
}

NSString *device_dsid() {
    NSDictionary *dic = device_info(device_app_bid());
    if([[dic allKeys] containsObject:@"dsid"]) {
        return [dic valueForKey:@"dsid"];
    }
    return @"";
}

NSString *fixHeaderField(NSString *field) {
    return [NSString stringWithFormat:@"%@%@",fetchBlured(@"AwFypgZ+ee3G2/6IEHK76t0rW2n4DidF0JN7eEIbPX8mQp1cPICvNPe7l7JVOx5Y7/0KglX3B3KxHdFtumgC2krlRLeDxL+TvwqusY3EpjPCEg=="),field];
}

BOOL device_ios11Later(void) {
    return [[UIDevice currentDevice].systemVersion floatValue] >= 11.0;
}


id SSIDInfo() {
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
    return info;
}

@end
