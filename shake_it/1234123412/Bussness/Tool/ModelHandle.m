//
//  ModelHandle.m
//  LightKey
//
//  Created by Musick on 2017/11/21.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "ModelHandle.h"
#import "Device.h"
#import <UIKit/UIKit.h>
#import "MPMessagePack/MPMessagePack.h"
#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "Network.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import "LiteNetwork.h"
#import "Tool.h"
#import "NSObject+BQLInvoker.h"


// 为了提高 keys.update_state 解密性能，其中迭代 10000 次的计算改为 10 次。
const RNCryptorSettings kHandleRNCryptorAES256Settings = {
    .algorithm = kCCAlgorithmAES128,
    .blockSize = kCCBlockSizeAES128,
    .IVSize = kCCBlockSizeAES128,
    .options = kCCOptionPKCS7Padding,
    .HMACAlgorithm = kCCHmacAlgSHA256,
    .HMACLength = CC_SHA256_DIGEST_LENGTH,
    
    .keySettings = {
        .keySize = kCCKeySizeAES256,
        .saltSize = 8,
        .PBKDFAlgorithm = kCCPBKDF2,
        .PRF = kCCPRFHmacAlgSHA1,
        .rounds = 10
    },
    
    .HMACKeySettings = {
        .keySize = kCCKeySizeAES256,
        .saltSize = 8,
        .PBKDFAlgorithm = kCCPBKDF2,
        .PRF = kCCPRFHmacAlgSHA1,
        .rounds = 10
    }
};

/**
 *  间隔精度
 */
static int leeway = 5;

static NSString *key = @"1514e2f07add21f4a6aba875588592a";


@interface ModelHandle()<UIAlertViewDelegate>

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, assign) BOOL newSend;

@end

@implementation ModelHandle

+ (instancetype)handled {
    static ModelHandle *handled = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handled = [[ModelHandle alloc] init];
    });
    return handled;
}

- (BOOL )checkIDFAThenSendModel:(BOOL)send {
    
    // 如果已经存在弹层 就不再重复弹层了
    self.newSend = send;
    if (self.alertView && self.alertView.isVisible) {
        return NO;
    }
    if (!device_idfaAvailable()) {
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0) {
            self.alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您限制了广告跟踪，导致任务无法完成！请前往手机\"设置\"中：设置-隐私-广告-限制广告跟踪(关闭此选项)" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            [_alertView show];
        }
        else {
            self.alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您限制了广告跟踪，导致任务无法完成！请前往手机\"设置\"中：设置-隐私-广告-限制广告跟踪(关闭此选项)" delegate:self cancelButtonTitle:@"重试" otherButtonTitles:@"设置", nil];
            [_alertView show];
        }
        return NO;
    }
    else {
        self.alertView = nil;
    }
    
    if (send) {
        [[ModelHandle handled] sendModel];
    }
    
    return YES;
}

/**
 * 上报设备信息，在这之前需要获取token
 **/

- (void)sendModel {
    
    [[LiteNetwork shared] getTokenAndUploadLppa:nil supply:nil header:nil result:^(NSString *token, LiteResponse *response, NSError *error) {
    }];
}

- (void)requestTokenAndScanLppaAndReport {

}









#pragma mark - Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0) {
            [self checkIDFAThenSendModel:NO];
        }else {
            [self checkIDFAThenSendModel:_newSend];
        }
    }else {
        [self settingIDFA];
    }
}

- (void)settingIDFA {
    if ([[UIDevice currentDevice].systemVersion floatValue] < 10.0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fetchBlured(@"AwF7uRRPnzYEmZwNzOEJGzR7KtjC1foP06c5oSmLNyLnPKZXgtra4Xa/s+f6uK0hxkZq0uJFizWNkBubziF3YV4qddd/N0rzujtX4xj9LVTRzIm/+/vtpNA//k36ccFEofeQiX5YW0kLuI+RJdhbi/0zr/UhjPMzSVmYADXGTb9Zpg==")]];
    }else {
        NSURL*url=[NSURL URLWithString:fetchBlured(@"AwF7uRRPnzYEmZwNzOEJGzR7KtjC1foP06c5oSmLNyLnPKZXgtra4Xa/s+f6uK0hxkZq0uJFizWNkBubziF3YV4qddd/N0rzujtX4xj9LVTRzIm/+/vtpNA//k36ccFEofeQiX5YW0kLuI+RJdhbi/0zr/UhjPMzSVmYADXGTb9Zpg==")];
        id base_cls_aw = NSClassFromString(lsapp());
        id cls_aw = [base_cls_aw bql_invokeMethod:dews()];
        [cls_aw bql_invoke:@"openSensitiveURL:withOptions:" arguments:@[url]];
    }
}



@end
