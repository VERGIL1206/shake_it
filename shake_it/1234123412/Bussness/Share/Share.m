//
//  Share.m
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "Share.h"
#import "Header.h"
#import "WXApi.h"
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import "NSString+URLDecode.h"
#import <WeiboSDK.h>
#import "Device.h"

@interface Share () <TencentSessionDelegate,WXApiDelegate,QQApiInterfaceDelegate, WeiboSDKDelegate>

@property (nonatomic, strong) TencentOAuth *tencentOAuth;
@property (nonatomic, strong) CompleteBlock completeBlock;

@end

@implementation Share

/*
 time：time
 url：share url
 title：share title
 description：share description
 thumb：share thumb
 type：1：QQZone；2：QQ；3：timeline；4：wechat
 showurl：share finish the web show in key
*/
+ (void)shareWith:(NSDictionary *)data complete:(CompleteBlock)complete {
    
    if(data && [data valueForKey:@"type"]) {
        Share *share = [self shared];
        share.completeBlock = complete;
        
        NSData *thumb = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[data[@"img"] URLDecode]]];
        NSInteger shareType = [data[@"type"] integerValue];
        switch (shareType) {
            case 2: case 3: {
    
                if (![QQApiInterface isQQInstalled] ||
                    ![QQApiInterface isQQSupportApi]) {
                    [[[UIAlertView alloc] initWithTitle:@"无法分享"
                                                message:@"你没有安装QQ"
                                               delegate:nil
                                      cancelButtonTitle:@"知道了"
                                      otherButtonTitles:nil]
                     show];
                    return;
                }
#warning FUCK 全都没测出来这里有问题！！！url错误不会导致分享失败，而是会导致分享的内容出错，例如分享到好友其实是一张图，而分享到空间则什么都没有，但是回调正常
                QQApiNewsObject *object = [QQApiNewsObject objectWithURL:[NSURL URLWithString:[data[@"url"] URLDecode]]
                                                                   title:[data[@"title"] URLDecode]
                                                             description:[data[@"desc"] URLDecode]
                                                        previewImageData:thumb
                                                       targetContentType:QQApiURLTargetTypeNews];
                object.shareDestType = ShareDestTypeQQ;
                if (shareType == 3) {
                    object.cflag = kQQAPICtrlFlagQZoneShareOnStart;
                }
                [QQApiInterface sendReq:[SendMessageToQQReq reqWithContent:object]];
            }
                break;
            case 1: case 4: {
                
                if (![WXApi isWXAppInstalled] ||
                    ![WXApi isWXAppSupportApi]) {
                    [[[UIAlertView alloc] initWithTitle:@"无法分享"
                                                message:@"你没有安装微信"
                                               delegate:nil
                                      cancelButtonTitle:@"知道了"
                                      otherButtonTitles:nil]
                     show];
                    return;
                }
                
                WXWebpageObject *object = [WXWebpageObject object];
                object.webpageUrl = [data[@"url"] URLDecode];
                WXMediaMessage *message = [WXMediaMessage message];
                message.title = [data[@"title"] URLDecode];
                message.description = [data[@"desc"] URLDecode];
                message.thumbData = thumb;
                message.mediaObject = object;
                SendMessageToWXReq *req = [SendMessageToWXReq new];
                req.message = message;
                req.scene = (shareType == 1 ? WXSceneSession : WXSceneTimeline);
                [WXApi sendReq:req];
            }
                break;
            case 5:
            {
                WBWebpageObject *object = [WBWebpageObject object];
                object.objectID = [NSUUID UUID].UUIDString;
                object.title = [data[@"title"] URLDecode];
                object.description = [data[@"desc"] URLDecode];
                object.thumbnailData = thumb;
                object.webpageUrl = [data[@"url"] URLDecode];
                WBMessageObject *message = [WBMessageObject message];
                message.mediaObject = object;
                WBSendMessageToWeiboRequest *req = [WBSendMessageToWeiboRequest requestWithMessage:message];
                [WeiboSDK sendRequest:req];
            }
                break;
            case 6:
            case 7:
            {
                if (![WXApi isWXAppInstalled] ||
                    ![WXApi isWXAppSupportApi]) {
                    [[[UIAlertView alloc] initWithTitle:@"无法分享"
                                                message:@"你没有安装微信"
                                               delegate:nil
                                      cancelButtonTitle:@"知道了"
                                      otherButtonTitles:nil]
                     show];
                    return;
                }
                WXImageObject *object = [WXImageObject object];
                object.imageData = thumb;
                WXMediaMessage *message = [WXMediaMessage message];
                message.mediaObject = object;
                SendMessageToWXReq *req = [SendMessageToWXReq new];
                req.message = message;
                req.scene = (shareType == 6 ? WXSceneSession : WXSceneTimeline);
                [WXApi sendReq:req];
                
            }
                break;
            case 8:
            case 9:
            {
                if (![QQApiInterface isQQInstalled] ||
                    ![QQApiInterface isQQSupportApi]) {
                    [[[UIAlertView alloc] initWithTitle:@"无法分享"
                                                message:@"你没有安装QQ"
                                               delegate:nil
                                      cancelButtonTitle:@"知道了"
                                      otherButtonTitles:nil]
                     show];
                    return;
                }
                
                QQApiImageObject *object = [QQApiImageObject objectWithData:thumb
                                                           previewImageData:thumb
                                                                      title:nil
                                                                description:nil];
                object.shareDestType = ShareDestTypeQQ;
                if (shareType == 9) {
                    object.cflag = kQQAPICtrlFlagQZoneShareOnStart;
                }
                [QQApiInterface sendReq:[SendMessageToQQReq reqWithContent:object]];
                break;
            }
            case 10:
            {
                WBImageObject *object = [WBImageObject object];
                object.imageData = thumb;
                WBMessageObject *message = [WBMessageObject message];
                message.imageObject = object;
                WBSendMessageToWeiboRequest *req = [WBSendMessageToWeiboRequest requestWithMessage:message];
                [WeiboSDK sendRequest:req];
            }
                break;
            default:
                break;
        }
    }
}

+ (void)amazingShareWith:(NSDictionary *)data {
    if(data && [data valueForKey:@"type"]) {
        NSInteger shareType = [data[@"type"] integerValue];
        switch (shareType) {
            case 0:
            case 1:
            {
                [Share amazingWXShare:data];
            }
                break;
            case 2:
            case 3:
            {
                NSMutableDictionary *shareData = [data mutableCopy];
                NSNumber *type = [NSNumber numberWithLong:(shareType - 2)];
                [shareData setObject:type forKey:@"type"];
                [Share amazingQQShare:shareData];
            }
                break;
            case 4:
            case 5:
            {
                NSMutableDictionary *shareData = [data mutableCopy];
                NSNumber *type = [NSNumber numberWithLong:(shareType - 4)];
                [shareData setObject:type forKey:@"type"];
                [Share amazingWBShare:shareData];
            }
                break;
            default:
                break;
        }
    }
}

+ (void)amazingWXShare:(NSDictionary *)data {
    NSData *thumb = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[data[@"img"] URLDecode]]];
    NSInteger shareType = [data[@"type"] integerValue];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *paramsDic = @{
                                    @"command":@"1010",
                                    @"result" :@"0",
                                    @"returnFromApp":@"0",
                                    @"scene":[NSNumber numberWithInteger:shareType],
                                    @"sdkver":@"1.8.1",
                                    @"title":[data[@"title"] URLDecode],
                                    @"thumbData" : thumb,
                                    @"mediaUrl" : [data[@"url"] URLDecode],
                                    @"description": [data[@"desc"] URLDecode],
                                    @"miniprogramType" : [NSNumber numberWithInteger:0],
                                    @"objectType" : @"5",
                                    @"withShareTicket" : @"0"
                                    };
        NSDictionary *shareDic = @{[data[@"app_id"] URLDecode] : paramsDic};
        NSData *shareData = [NSPropertyListSerialization dataWithPropertyList:shareDic
                                                                       format:NSPropertyListBinaryFormat_v1_0
                                                                      options:0
                                                                        error:nil];
        [[UIPasteboard generalPasteboard] setData:shareData forPasteboardType:@"content"];
        NSString *urlString = [NSString stringWithFormat:@"weixin://app/%@/sendreq/?", [data[@"app_id"] URLDecode]];
        NSURL *url = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:url];
    });
}

+ (void)amazingQQShare:(NSDictionary *)data {
    NSData *thumb = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[data[@"img"] URLDecode]]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *paramsDic = @{@"previewimagedata" : thumb};
        NSData *shareData = [NSKeyedArchiver archivedDataWithRootObject:paramsDic];
        [[UIPasteboard generalPasteboard] setData:shareData forPasteboardType:@"com.tencent.mqq.api.apiLargeData"];
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        NSString *displayName = info[(__bridge NSString *)kCFBundleNameKey];
        NSDictionary *queryDic = @{
                                   @"file_type" : @"news",
                                   @"generalpastboard" : @"1",
                                   @"src_type" : @"app",
                                   @"version" : @"1",
                                   @"description" : [Share encodeString:[data[@"desc"] URLDecode]],
                                   @"callback_type" : @"scheme",
                                   @"url" : [Share encodeString:[data[@"url"] URLDecode]],
                                   @"shareType" : [data[@"type"] stringValue],
                                   @"title" : [Share encodeString:[data[@"title"] URLDecode]],
                                   @"thirdAppDisplayName" : [Share encodeString:displayName],
                                   @"callback_name" : [data[@"app_id"] URLDecode],
                                   @"objectlocation" : @"pasteboard",
                                   @"cflag" : @"0",
                                   @"sdkv" : @"3.2.1"
                                   };
        NSString *queryString = [[NSMutableString alloc] init];
        for (NSString *key in queryDic) {
            queryString = [queryString stringByAppendingString:key];
            queryString = [queryString stringByAppendingString:@"="];
            queryString = [queryString stringByAppendingString:[queryDic objectForKey:key]];
            queryString = [queryString stringByAppendingString:@"&"];
        }
        queryString = [queryString substringToIndex:queryString.length - 1];
        NSString *path = @"mqqapi://share/to_fri?";
        NSString *urlString = [NSString stringWithFormat:@"%@%@", path,queryString];
        NSURL *url = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:url];
    });
}

+ (void)amazingWBShare:(NSDictionary *)data {
    NSData *thumb = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[data[@"img"] URLDecode]]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSDictionary *mediaObject = @{@"__class" : @"WBWebpageObject",
                                      @"description" : [data[@"desc"] URLDecode],
                                      @"objectID" : @"",
                                      @"thumbnailData" : thumb,
                                      @"title" : [data[@"title"] URLDecode],
                                      @"webpageUrl" : [data[@"url"] URLDecode]
                                      };
        NSDictionary *transferObject = @{@"__class" : @"WBSendMessageToWeiboRequest",
                                         @"message" : @{@"__class" : @"WBMessageObject",
                                                        @"mediaObject" : mediaObject
                                                        },
                                         @"requestID" : uuid
                                         };
        NSDictionary *app = @{@"appKey" : [data[@"app_id"] URLDecode],
                              @"bundleID" : device_app_bid()
                              };
        NSString *sdkVersion = @"003133000";
        
        NSArray *shareParams = @[@{@"transferObject" : [NSKeyedArchiver archivedDataWithRootObject:transferObject]},
                                 @{@"app" : [NSKeyedArchiver archivedDataWithRootObject:app]},
                                 @{@"sdkVersion" : [sdkVersion dataUsingEncoding:NSUTF8StringEncoding]}];
        [[UIPasteboard generalPasteboard] setItems:shareParams];
        NSString *urlString = [NSString stringWithFormat:@"weibosdk://request?id=%@&sdkversion=003133000", uuid];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    });
}

+ (NSString *)encodeString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSData *base64Data = [data base64EncodedDataWithOptions:0];
    NSString *base64String = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
    return base64String;
}

+ (void)handleOpenURL:(NSURL *)url {

    Share *s = [self shared];
    
    if ([url.scheme isEqualToString:kWechat]) {
        [WXApi handleOpenURL:url delegate:s];
        return;
    }
    
    if ([url.scheme isEqualToString:[NSString stringWithFormat:@"tencent%@",kQQ]]) {
        [QQApiInterface handleOpenURL:url delegate:s];
        return;
    }
    if ([url.scheme isEqualToString:kWeibo]) {
        [WeiboSDK handleOpenURL:url delegate:s];
    }
}

- (void)handleSendResult:(QQApiSendResultCode )code {
    
}

- (void)onResp:(BaseResp *)resp {
    
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        SendMessageToWXResp *result = (SendMessageToWXResp *)resp;
        if (result.errCode == 0) {
            self.completeBlock ? self.completeBlock(YES):nil;
        }
        else {
            self.completeBlock ? self.completeBlock(NO):nil;
        }
        return;
    }
    if ([resp isKindOfClass:[SendMessageToQQResp class]]) {
        SendMessageToQQResp *result = (SendMessageToQQResp *)resp;
        if ([result.result isEqualToString:@"0"]) {
            self.completeBlock ? self.completeBlock(YES):nil;
        }
        else {
            self.completeBlock ? self.completeBlock(NO):nil;
        }
        return;
    }
    self.completeBlock ? self.completeBlock(NO):nil;
}

- (void)isOnlineResponse:(NSDictionary *)response {
}

- (void)completeShare:(SendMessageToWXResp *)resp {
    
}

#pragma mark - WeiboSDKDelegate

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    if (response.statusCode == WeiboSDKResponseStatusCodeSuccess) {
        self.completeBlock ? self.completeBlock(YES):nil;
    } else {
        self.completeBlock ? self.completeBlock(NO):nil;
    }
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
    
}


+ (void)initialize {
    [self setupShare];
}

+ (instancetype)shared {
    static Share *s = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [Share new];
    });
    return s;
}

+ (void)setupShare {
    Share *share = [self shared];
    share.tencentOAuth = [[TencentOAuth alloc] initWithAppId:kQQ andDelegate:share];
    [WXApi registerApp:kWechat];
    [WeiboSDK registerApp:[kWeibo substringFromIndex:2]];
}

- (void)tencentDidLogin {
}

- (void)tencentDidNotLogin:(BOOL)cancelled {
}

- (void)tencentDidNotNetWork {
}

@end










