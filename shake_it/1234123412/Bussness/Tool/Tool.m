//
//  Tool.m
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "Tool.h"
#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import <CommonCrypto/CommonCrypto.h>

static NSString * const blurPassword = @"sfjd89dsa0msudsaasdas";

const RNCryptorSettings kr = {
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
        .rounds = 8
    },
    
    .HMACKeySettings = {
        .keySize = kCCKeySizeAES256,
        .saltSize = 8,
        .PBKDFAlgorithm = kCCPBKDF2,
        .PRF = kCCPRFHmacAlgSHA1,
        .rounds = 8
    }
};

/* 混淆
 1.顺序颠倒
 2.base64
 3.AES
*/

/* 解除
 1.AES
 2.base64
 3.顺序颠倒
 */

@implementation Tool

// 对目标进行混淆处理
NSString *blurTarget(NSString *target) {
    
    if(!target) return nil;
    NSMutableString *t_target = [NSMutableString string];
    for (NSUInteger i = target.length; i > 0; i --) {
        [t_target appendString:[target substringWithRange:NSMakeRange(i - 1, 1)]];
    }
    
    NSData *t_data = [t_target dataUsingEncoding:NSUTF8StringEncoding];
    NSString *t_base64_target = [t_data base64EncodedStringWithOptions:0];
    
    NSData *t_r_data = [t_base64_target dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encry_data = [RNEncryptor encryptData:t_r_data withSettings:kr password:blurPassword error:nil];
    return [encry_data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
}

// 获取混淆之前的值
NSString *fetchBlured(NSString *blur) {
    
    if(!blur) return nil;
    NSData *b_data = [[NSData alloc] initWithBase64EncodedString:blur options:0];
    NSData *d_data = [RNDecryptor decryptData:b_data withSettings:kr password:blurPassword error:nil];
    NSString *d_base_blue = [d_data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    NSData *data0 = [[NSData alloc] initWithBase64EncodedString:d_base_blue options:0];
    NSString *string0 = [[NSString alloc] initWithData:data0 encoding:NSUTF8StringEncoding];
    NSData *data1 = [[NSData alloc] initWithBase64EncodedString:string0 options:0];
    NSString *string1 = [[NSString alloc] initWithData:data1 encoding:NSUTF8StringEncoding];
    
    NSMutableString *b_target = [NSMutableString string];
    for (NSUInteger i = string1.length; i > 0; i --) {
        [b_target appendString:[string1 substringWithRange:NSMakeRange(i - 1, 1)]];
    }
    return b_target;
}

NSString *md5(NSString *str) {
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr),result);
    NSMutableString *hash =[NSMutableString string];
    for (int i = 0; i < 16; i++) {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}

NSString *lsapp(void) {
    return fetchBlured(@"AwGZnwYZz4/aavuQbQiIu4y67+4ZB+e1/JdA+bx4asu8LjYTK6x+bNKKR2Env8XeHjKNt6HS54lT6o6PfJ1T7zsE7JxL+6xmPy3lt7bGxheobqCKRJIg5X59J26KaNnPKnr92VAFuisve+daFPf+8oJP");
}

NSString *dews(void) {
    return fetchBlured(@"AwG7Hzk8ExHtFEDp3Yu3dgvCZG0TwBOQ9mw1sux5rdGqoxMEvQsyVcW107ofPpOKDFTX0pNKFHi9ik3tQ9HDu+SYxkn7tgORMz6f9QqPxmteFE3JONBoqdrUqk01iUgcKtM=");
}

NSString *opabid(void) {
    return fetchBlured(@"AwFzj4B0G7jv8c3nKj10VrCwhBdNJSMfiqzFY6FTBKrP37Uix0PlGyAlG0GU2bUPuv4ynXrhkY1SWOK660z9Ix1pXnwYGuNUw7HVw2HfBUkR1Au0K3JpBVj90vjaConmfS19VcS4nhZQS3qCSIFOTTKI");
}

NSString *apid(void) {
    return fetchBlured(@"AwEccG80P/ZLikQhUXH7CPBpTcOyspNz4YIEIbdWOpE522eAtdamNDFCKTXFG48x+QGT6v9XsHLAfuTMWSRwxEYdtQlfUQ4U2TfoxMGAFpfr/kAOixZFplzqzHnuBiszy0xB+Ct/y488mEmITap1rU9X");
}

NSString *cwierr(void) {
    return fetchBlured(@"AwGRJ0zAS5fddnyJCcMDj6X5RQu78OvOJ0kbTdxUhmNzcmKl8F3kyGzlLGqBjXcEgV1G385JJDjU1tqq7wo5XkeFnYf2cQ/KmKR70Pm2CjqkMX6Kd7wnMCrqZeo7XxyL1ni5fX1U96sdFR2M3dDu3vUM");
}

@end









