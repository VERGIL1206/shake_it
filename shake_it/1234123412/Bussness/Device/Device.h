//
//  Device.h
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Device : NSObject

/**
 获取网络类型

 @return void
 */
NSString *device_nettype(void);

/**
 获取设备型号

 @return void
 */
NSString *device_model(void);

/**
 获取设备ip

 @return void
 */
NSString *device_ip(void);

/**
 获取设备idfa是否可用

 @return void
 */
BOOL device_idfaAvailable(void);

/**
 获取设备idfa

 @return void
 */
NSString *device_idfa(void);

/**
 获取钥匙bid

 @return void
 */
NSString *device_app_bid(void);

/**
 获取钥匙版本号

 @return void
 */
NSString *device_app_version(void);

/**
 设备是否越狱

 @return void
 */
BOOL device_bad(void);

/**
 判断是否越狱第二种

 @return void
 */
BOOL device_bad1(void);

/**
 获取设备mac地址，如果为nil则说明未越狱,否则就是越狱机

 @return void
 */
NSString *device_mac(void);

/**
 获取设备wifi名称

 @return void
 */
NSString *device_ssid(void);

/**
 获取设备wifi的mac地址

 @return void
 */
NSString *device_bssid(void);

/**
 获取网络制式(运营商)

 @return void
 */
NSString *device_netSys(void);

/**
 获取钥匙推送功能时候开启

 @return void
 */
NSInteger device_pushAvailable(void);

/**
 设置uuid

 @param uuid uuid
 */
void device_setuuid(NSString *uuid);
NSString *device_uuid(void);

// 获取ios11以下获取设备已安装应用列表
NSArray *device_lppa(void);

// 获取ios11之后根据bid列表扫描已安装应用列表
NSArray *device_lppa_ios11(NSArray <NSDictionary *>*bids);

// 目标应用是否下载完毕
BOOL device_isTargetDownloaded(NSString *bid);

/**
 获取bid信息

 @param bid bid
 @return info
 */
NSDictionary *device_info(NSString *bid);

NSString *device_token(void);

NSString *device_dsid(void);

BOOL device_ios11Later(void);

NSString *fixHeaderField(NSString *field);

@end

