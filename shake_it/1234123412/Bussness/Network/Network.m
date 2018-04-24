//
//  Network.m
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "Network.h"
#import <AFNetworking/AFNetworking.h>
#import "Device.h"
#import "JPUSHService.h"
#import "NSString+URLDecode.h"
#import <CommonCrypto/CommonCrypto.h>
#import "RNEncryptor.h"
#import "NSDictionary+MPMessagePack.h"
#import "Tool.h"

const RNCryptorSettings signk = {
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

@interface Network()

@property (nonatomic, strong) AFHTTPRequestSerializer *serializer;
@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation Network

- (instancetype)init {
    if (self == [super init]) {
        self.serializer = [AFHTTPRequestSerializer serializer];
        self.serializer.timeoutInterval = 10.f;
        self.manager = [AFHTTPSessionManager manager];
        self.host = [[NSUserDefaults standardUserDefaults] objectForKey:@"default_host"];
    }
    return self;
}

+ (instancetype)shared {
    static Network *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Network alloc] init];
    });
    return shared;
}

- (void)AsyncGETWithHost:(NSString *)host path:(NSString *)path params:(NSDictionary *)params header:(NSDictionary *)header sign:(BOOL)sign block:(apiRespose)block {
    
    NSMutableURLRequest *request = [self requestWithHost:host method:@"GET" path:path params:params];
    if (sign) {
        request = [[self signWithRequest:request params:params header:header] mutableCopy];
    }
    [self callRequest:request
       handleResponse:^(NSURLRequest *request, LKRespose *response)
     {
         block(request, response);
         NSLog(@"%@", response);
     }];
}

- (void)AsyncPOSTWithHost:(NSString *)host path:(NSString *)path body:(NSDictionary *)body header:(NSDictionary *)header sign:(BOOL)sign block:(apiRespose)block {
    
    NSMutableURLRequest *request = [self requestWithHost:host method:@"POST" path:path params:body];
    
    NSData *data = [RNEncryptor encryptData:[body mp_messagePack] withSettings:signk password:@"1514e2f07add21f4a6aba875588592a" error:nil];
    request.HTTPBody = data;
    
    if (sign) {
        request = [[self signWithRequest:request params:body header:header] mutableCopy];
    }
    
    [self callRequest:request
       handleResponse:^(NSURLRequest *request, LKRespose *response)
     {
         block(request, response);
         NSLog(@"%@", response);
     }];
}

- (NSMutableURLRequest *)requestWithHost:(NSString *)host
                                  method:(NSString *)method
                                    path:(NSString *)path
                                  params:(NSDictionary *)params {
    NSMutableString *url = [[NSMutableString alloc] init];
    if (host) {
        url = [NSMutableString stringWithFormat:@"%@", [host stringByAppendingString:path]];
    }else {
        url = [NSMutableString stringWithFormat:@"%@", [self.host stringByAppendingString:path]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = method;
    NSError *error = nil;
    request = (NSMutableURLRequest *)[self.serializer requestBySerializingRequest:request
                                                                   withParameters:params
                                                                            error:&error];
    if (error) {
        return nil;
    }
    return request;
}

- (NSURLRequest *)signWithRequest:(NSURLRequest *)request
                           params:(NSDictionary *)params
                           header:(NSDictionary *)header{
    
    NSMutableURLRequest *signRequest = [request mutableCopy];
    //如果是转发的request，host还是127.0.0.1，所以这里还需要将host替换成服务端的host
    [signRequest setValue:[request.URL host] forHTTPHeaderField:@"Host"];
    
    [signRequest setValue:[NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
       forHTTPHeaderField:fixHeaderField(@"TIME")];
#warning key可能需要改
    [signRequest setValue:@"c26007f41f472932454ea80deabd612c"
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

    [signRequest setValue:device_token()
       forHTTPHeaderField:fixHeaderField(@"TAG")];

    //check content type
    NSString *inputType = [signRequest valueForHTTPHeaderField:@"Content-Type"];
    BOOL isBodyDic = [inputType isEqualToString:@"multipart/form-data"] || [inputType isEqualToString:@"application/x-www-form-urlencoded"];
    
    //get input params
    //NSMutableDictionary *inputParams = [NSMutableDictionary dictionaryWithDictionary:params];
    NSMutableDictionary *inputParams = [NSMutableDictionary dictionaryWithDictionary:[self paramsFromQuery:signRequest.URL.query]];
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
    NSString *path = request.URL.path;
    NSString *signString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                            path,           //去掉 '/servises/'前缀的 path
                            [signArray componentsJoinedByString:@"+"],
                            @"aa005ddfcdfed328878fb81e76cc2969",
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
    
    return signRequest;
}

- (NSDictionary *)paramsFromQuery:(NSString *)query {
    NSMutableDictionary<NSString *, id> *map = [NSMutableDictionary dictionary];
    for (NSString *item in [query componentsSeparatedByString:@"&"]) {
        NSArray *kv = [item componentsSeparatedByString:@"="];
        if (kv.count == 2) {
            map[kv.firstObject] = [self URLDecode:kv.lastObject];
        }
    }
    return map;
}

- (NSString *)URLDecode:(NSString *)encoded {
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0
    NSString *decodedString =
    (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                          (__bridge CFStringRef)encoded,
                                                                                          CFSTR(""),
                                                                                          CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
#else
    NSString *decodedString = (__bridge NSString *)CFURLCreateStringByReplacingPercentEscapes(nil, (__bridge CFStringRef)encoded, CFSTR(""));
#endif
    
    return decodedString;
}

- (void)callRequest:(NSURLRequest *)request handleResponse:(apiRespose)block {
    
    NSURLSessionDataTask *task = [self.manager dataTaskWithRequest:request
                                                           uploadProgress:^(NSProgress *uploadProgress){}
                                                         downloadProgress:^(NSProgress *downloadProgress){}
                                                        completionHandler:^(NSURLResponse *response,
                                                                            id responseObject,
                                                                            NSError *error)
                                  {
                                      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                      LKRespose *res = nil;
                                      if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                          res = [LKRespose respose:httpResponse
                                                               style:LKResposeStyleJSON
                                                                data:responseObject
                                                               error:error];
                                      } else {
                                          res = [LKRespose respose:httpResponse
                                                               style:LKResposeStyleData
                                                                data:responseObject
                                                               error:error];
                                      }
                                      
                                      if (block) {
                                          block(request, res);
                                      }
                                  }];
    
    [task resume];
}

- (NSString*)dictionaryToJson:(NSDictionary *)dic {
    
    if(!dic) return @"";
    
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


@end
