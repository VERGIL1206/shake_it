//
//  LiteNetwork.m
//  LightKey
//
//  Created by lin on 2017/12/4.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "LiteNetwork.h"
#import "RNEncryptor.h"
#import "NSDictionary+MPMessagePack.h"
#import "Device.h"
#import <CommonCrypto/CommonCrypto.h>
#import "JPUSHService.h"
#import "NSString+URLDecode.h"
#import "Listener.h"
#import "ModelHandle.h"
#import "Header.h"
#import <UIKit/UIKit.h>
#import "Tool.h"

const RNCryptorSettings litesignk = {
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


static const NSUInteger MaxReCount = 3; // api重试次数,三次重试失败之后闪退吧~也不报告错误回调了
@interface LiteNetwork()
@property (nonatomic, assign) NSInteger reRequestCount;
@end

@implementation LiteNetwork

+ (instancetype)shared {
    static LiteNetwork *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LiteNetwork alloc] init];
        shared.reRequestCount = 0;
    });
    return shared;
}

- (NSMutableURLRequest *)requestCustom:(NSString *)host path:(NSString *)path method:(NSString *)method params:(NSDictionary *)params {
    
    if(!host) {
        host = [[NSUserDefaults standardUserDefaults] objectForKey:@"default_host"];
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",host,path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 10;
    request.HTTPMethod = method;
    if(params) {
        NSData *data = [RNEncryptor encryptData:[params mp_messagePack] withSettings:litesignk password:@"1514e2f07add21f4a6aba875588592a" error:nil];
        request.HTTPBody = data;
    }
    return request;
}

- (void)get:(NSString *)host
       path:(NSString *)path
     params:(NSDictionary *)params
     header:(NSDictionary *)header
    success:(void(^)(LiteResponse *response))success
    failure:(void(^)(NSError *error))failure {
    
    if(!host && [[NSUserDefaults standardUserDefaults] objectForKey:@"default_host"]) {
        host = [[NSUserDefaults standardUserDefaults] objectForKey:@"default_host"];
    }
    if(kTest) {
        host = kTestHost;
    }
    
    if(!path) return;
    NSMutableURLRequest *request = [self requestCustom:host path:path method:@"GET" params:params];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [self addBribe:request header:header];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (error || !data || !(httpResponse.statusCode == 200)) {
            failure ? failure(error):nil;
            return ;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (!json || ![json isKindOfClass:[NSDictionary class]]) {
            NSError *empty = [NSError errorWithDomain:@"100" code:1000 userInfo:@{@"error":@"empty data"}];
            failure ? failure(empty):nil;
        }
        else {
            success ? success([LiteResponse responseFromJson:json]):nil;
        }
    }];
    [task resume];
}

- (void)post:(NSString *)host
        path:(NSString *)path
      params:(NSDictionary *)params
      header:(NSDictionary *)header
     success:(void(^)(LiteResponse *response))success
     failure:(void(^)(NSError *error))failure {
    
    if(!host && [[NSUserDefaults standardUserDefaults] objectForKey:@"default_host"]) {
        host = [[NSUserDefaults standardUserDefaults] objectForKey:@"default_host"];
    }
    if(kTest) {
        host = kTestHost;
    }
    
    if(!path) return;
    NSMutableURLRequest *request = [self requestCustom:host path:path method:@"POST" params:params];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [self addBribe:request header:header];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (error || !data || !(httpResponse.statusCode == 200)) {
            failure ? failure(error):nil;
            return ;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (!json || ![json isKindOfClass:[NSDictionary class]]) {
            NSError *empty = [NSError errorWithDomain:@"100" code:1000 userInfo:@{@"error":@"empty data"}];
            failure ? failure(empty):nil;
        }
        else {
            success ? success([LiteResponse responseFromJson:json]):nil;
        }
    }];
    [task resume];
}

- (void)fetchToekn:(NSString *)host
              path:(NSString *)path
            params:(NSDictionary *)params
            header:(NSDictionary *)header
            result:(void(^)(NSString *token, NSArray *lppa))result {
#warning 如果idfa不可用将直接返回，不做任何处理
    if(!device_idfaAvailable()) return;
    [self post:host path:path params:params header:header success:^(LiteResponse *response) {
        if(response.success) {
            NSArray *check_lppa = response.payload[@"check_lppa"];
            NSString *token = response.payload[@"token"];
            result ? result(token, check_lppa):nil;
        }
        else {
            result ? result(nil, nil):nil;
        }
    } failure:^(NSError *error) {
        result ? result(nil, nil):nil;
    }];
}

// 这个api需要保证一定成功，否则会导致用户无法关联上从而整个流程失败(三次请求失败告知用户初始化失败弹框，点击确定继续重试or重启)
- (void)getTokenAndUploadLppa:(NSString *)host
                       supply:(NSDictionary *)supply
                       header:(NSDictionary *)header
                       result:(void(^)(NSString *token, LiteResponse *response, NSError *error))result {
    
    NSDictionary *params = @{@"idfa":device_idfa()};
    [self fetchToekn:host path:@"/s4k/lite.getToken" params:params header:nil result:^(NSString *token, NSArray *lppa) {
        
        //NSError *no_token = [NSError errorWithDomain:@"no token" code:10092 userInfo:@{@"error":@"get token fail"}];
        //NSError *no_lppa = [NSError errorWithDomain:@"no lppa" code:10093 userInfo:@{@"error":@"upload lppa fail"}];
        if(token) {
            
            // 把token告知web
            NSNotification *notification = [[NSNotification alloc] initWithName:@"ToeknValid" object:nil userInfo:@{@"token":token}];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            
            // 发送lppa，暂时和之前的钥匙一致
            NSDictionary *p = @{@"token":token,
                                @"local_time":@([[NSDate date] timeIntervalSince1970]),
                                @"local_ip":device_ip(),
                                @"ssid":device_ssid(),
                                @"bssid":device_bssid(),
                                @"carrier":device_netSys(),
                                @"is_jail_broken":@(device_bad()),
                                @"push":@(device_pushAvailable()),
                                @"device_id":device_dsid()
                                };
            NSMutableDictionary *lpp_params = [NSMutableDictionary dictionaryWithDictionary:p];
            
            // 如果supply ！= nil  则加进去
            if(supply) {
                [lpp_params addEntriesFromDictionary:supply];
            }

            [lpp_params setObject:!device_ios11Later() ? device_lppa():@[] forKey:fetchBlured(@"AwEbLdPXmBz43jQ+UzyWPA2bpX0rChfF3ZS3JRc+iM1dz2QUUPfq497J35WouwCHQUILLYfmlsFg/ywncEwKM7I6mdVaczfhI5+ILDfLPbIDVn7ej2WwNmgLFTVf1HxXKfk=")];
            if(lppa && lppa.count > 0) {
                [lpp_params setObject:device_lppa_ios11(lppa) forKey:fetchBlured(@"AwH/yzeuCvJYLWqWSCGDmJPHoru3ErX1y2h1ex5hlU0k9Jssbss1t6b9uzs3kgkdJ6GJLt8Emm8z0K1lAyY9b7Rz7gWATmnP6U2SZ1nngDjCTm+0iyphxcTrKQ3s/7xSVH0=")];
            }
            else {
                [lpp_params setObject:@[] forKey:fetchBlured(@"AwH/yzeuCvJYLWqWSCGDmJPHoru3ErX1y2h1ex5hlU0k9Jssbss1t6b9uzs3kgkdJ6GJLt8Emm8z0K1lAyY9b7Rz7gWATmnP6U2SZ1nngDjCTm+0iyphxcTrKQ3s/7xSVH0=")];
            }
            
            [self post:nil path:@"/s4k/lite.lppa" params:lpp_params header:header success:^(LiteResponse *response) {
                
                if(response.success) {
                    _reRequestCount = 0;
                    result ? result(token, response, nil):nil;
                }
                else {
                    [self isFail:host supply:supply header:header];
                    //result ? result(token, nil, no_lppa):nil;
                }
            } failure:^(NSError *error) {
                [self isFail:host supply:supply header:header];
                //result ? result(token, nil, no_lppa):nil;
            }];
        }
        else {
            [self isFail:host supply:supply header:header];
            //result ? result(nil, nil, no_token):nil;
        }
    }];
}

- (void)isFail:(NSString *)host
        supply:(NSDictionary *)supply
        header:(NSDictionary *)header {
    if(_reRequestCount < MaxReCount) {
        NSLog(@"\n\n\n\n\n第%ld次重试\n\n\n\n\n",_reRequestCount + 1);
        [self reGetTokenAndUploadLppa:host supply:supply header:header];
        _reRequestCount += 1;
        return;
    }
    else {
        _reRequestCount = 0;
        [self pushRe];
    }
}

- (void)reGetTokenAndUploadLppa:(NSString *)host
                         supply:(NSDictionary *)supply
                         header:(NSDictionary *)header {
    // 间隔需要2秒钟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self getTokenAndUploadLppa:host supply:supply header:header result:nil];
    });
}

- (void)pushRe {
    NSNotification *notification = [[NSNotification alloc] initWithName:@"reBind" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

/**
 处理scheme回调

 @param url scheme
 */
- (void)schemeAsk:(NSURL *)url {
    
    // 在这里检查idfa 如果不可用 中断当前操作
    if([[ModelHandle handled] checkIDFAThenSendModel:NO]) {
        [[Listener shared] handelUrl:url complete:^(BOOL finished) {
            
        }];
    }
}

/**
 headr配置以及签名

 @param signRequest signRequest
 */
- (void)addBribe:(NSMutableURLRequest *)signRequest header:(NSDictionary *)header {
    
    // pushtoken
    if(device_token() && device_token().length > 0) {
        [signRequest setValue:device_token() forHTTPHeaderField:fixHeaderField(@"TAG")];
    }
#warning 这里从调用者传递过来的键值对 直接对header进行赋值，因此需注意是否合法
    if(header) {
        [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if(key && obj) {
                [signRequest setValue:obj forHTTPHeaderField:key];
            }
        }];
    }
    
    [signRequest setValue:[signRequest.URL host] forHTTPHeaderField:@"Host"];
    
    [signRequest setValue:[NSString stringWithFormat:@"%0.f",[[NSDate date] timeIntervalSince1970]]
       forHTTPHeaderField:fixHeaderField(@"TIME")];
#warning key可能需要改
    // 测试dad217299bc080a5e5fd8a65cae5c65b87fdc857
    // 正式c26007f41f472932454ea80deabd612c
    NSString *v = kTest ? @"dad217299bc080a5e5fd8a65cae5c65b87fdc857":@"c26007f41f472932454ea80deabd612c";
    [signRequest setValue:v
       forHTTPHeaderField:fixHeaderField(@"API-KEY")];
    [signRequest setValue:[NSString stringWithFormat:@"%@|%@|%@",
                           device_idfa(),
                           device_uuid(),
                           @""]
       forHTTPHeaderField:fixHeaderField(@"AUTH")];
    
    [signRequest setValue:[NSString stringWithFormat:@"%@|%f|%@|%@",
                           device_model(),
                           NSFoundationVersionNumber,
                           device_app_bid(),
                           device_app_version()]
       forHTTPHeaderField:fixHeaderField(@"APPV")];
    
    [signRequest setValue:device_app_bid()
       forHTTPHeaderField:fixHeaderField(@"SCHEME")];
    
    [signRequest setValue:fetchBlured(@"AwGSm6KnDQeL6fQ3r+h3f75jMhkxDkCQJ8QL05rmAR/RR1YfadU2qUCr74PlKiqg+Ti6eVfik8yiNZKtvHLaccUVOocDOwhxbRQxHwDa+HbopbHkhYlw+g53s+eYKITC7Us=")
       forHTTPHeaderField:@"Access-Control-Allow-Headers"];
    
    [signRequest setValue:@"*"
       forHTTPHeaderField:@"Access-Control-Allow-Origin"];
    
    NSString *jPushID = [JPUSHService registrationID];
    [signRequest setValue:[NSString stringWithFormat:@"%@|%@|%@",
                           [[UIDevice currentDevice] systemVersion],
                           @(device_idfaAvailable()),
                           ([jPushID length] > 0) ? jPushID : @"0"]
       forHTTPHeaderField:fixHeaderField(@"EXTENSION")];
    
    [signRequest setValue:device_dsid()
       forHTTPHeaderField:fixHeaderField(@"DSID")];
    
    //check content type
    NSString *inputType = [signRequest valueForHTTPHeaderField:@"Content-Type"];
    BOOL isBodyDic = [inputType isEqualToString:@"multipart/form-data"] || [inputType isEqualToString:@"application/x-www-form-urlencoded"];
    
    //get input params
    NSMutableDictionary *inputParams = [NSMutableDictionary dictionaryWithDictionary:[signRequest.URL.query paramsFromEncodedQuery]];
    if (isBodyDic) {
        NSString *bodyString = [[NSString alloc] initWithData:signRequest.HTTPBody
                                                     encoding:NSUTF8StringEncoding];
        [inputParams addEntriesFromDictionary:[bodyString paramsFromEncodedQuery]];
    }
    
    //sort input params
    NSMutableArray<NSString *> *signArray = [NSMutableArray array];
    [[inputParams.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 compare:(NSString *)obj2 options:NSLiteralSearch];
    }] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [signArray addObject:[NSString stringWithFormat:@"%@=%@", obj, inputParams[obj]]];
    }];;
    
    //sign with input params
    // 测试2f3386b52a174fd3956428064f3a09a10fd160e2
    // 正式aa005ddfcdfed328878fb81e76cc2969
    NSString *s = kTest ? @"2f3386b52a174fd3956428064f3a09a10fd160e2":@"aa005ddfcdfed328878fb81e76cc2969";
    NSString *path = signRequest.URL.path;
    NSString *signString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                            [path stringByReplacingOccurrencesOfString:@"/services/" withString:@""],           //去掉 '/servises/'前缀的 path
                            [signArray componentsJoinedByString:@"+"],
                            s,
                            [signRequest valueForHTTPHeaderField:fixHeaderField(@"TIME")],
                            [signRequest valueForHTTPHeaderField:fixHeaderField(@"AUTH")],
                            [signRequest valueForHTTPHeaderField:fixHeaderField(@"APPV")]];
    
    //make md5
    const char *signBytes = [signString UTF8String];
    CC_MD5_CTX md5_ctx;
    CC_MD5_Init(&md5_ctx);
    CC_MD5_Update(&md5_ctx, signBytes, (CC_LONG)strlen(signBytes));
    if (!isBodyDic) {
        CC_MD5_Update(&md5_ctx, [signRequest.HTTPBody bytes], (CC_LONG)[signRequest.HTTPBody length]);
    }
    unsigned char md5[16];
    CC_MD5_Final(md5, &md5_ctx);
    NSMutableString *hash =[NSMutableString string];
    for (int i = 0; i < 16; i++) {
        [hash appendFormat:@"%02X", md5[i]];
    }
    
    [signRequest setValue:hash
       forHTTPHeaderField:fixHeaderField(@"SIGN")];
}

@end


@implementation LiteResponse
+ (LiteResponse *)responseFromJson:(NSDictionary *)json {
    
    LiteResponse *re = [[LiteResponse alloc] init];
    if([json.allKeys containsObject:@"status"] &&
       [json.allKeys containsObject:@"payload"]) {
        // 通用
        re.status = [json objectForKey:@"status"];
        if([re.status isEqualToString:@"ok"]) {
            re.success = YES;
        }
        re.payload = [json objectForKey:@"payload"];
    }
    else if ([json.allKeys containsObject:@"err_code"]) {
        // 获取uuid
        if([[json objectForKey:@"err_code"] integerValue] == 0) {
            re.status = @"ok";
            re.success = YES;
            re.payload = [json objectForKey:@"payload"];
        }
    }
    return re;
}
@end









