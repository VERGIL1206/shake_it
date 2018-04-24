//
//  LiteNetwork.h
//  LightKey
//
//  Created by lin on 2017/12/4.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LiteResponse : NSObject
@property (nonatomic) BOOL success;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, strong) NSDictionary *payload;
+ (LiteResponse *)responseFromJson:(NSDictionary *)json;
@end

@interface LiteNetwork : NSObject

+ (instancetype)shared;

- (void)addBribe:(NSMutableURLRequest *)signRequest header:(NSDictionary *)header;

- (void)get:(NSString *)host
       path:(NSString *)path
     params:(NSDictionary *)params
     header:(NSDictionary *)header
    success:(void(^)(LiteResponse *response))success
    failure:(void(^)(NSError *error))failure;

- (void)post:(NSString *)host
        path:(NSString *)path
      params:(NSDictionary *)params
      header:(NSDictionary *)header
     success:(void(^)(LiteResponse *response))success
     failure:(void(^)(NSError *error))failure;

- (void)fetchToekn:(NSString *)host
              path:(NSString *)path
            params:(NSDictionary *)params
            header:(NSDictionary *)header
            result:(void(^)(NSString *token, NSArray *lppa))result;

/**
 获取token 并上报信息

 @param host header
 @param supply supply
 @param header header
 @param result result
 */
- (void)getTokenAndUploadLppa:(NSString *)host
                       supply:(NSDictionary *)supply
                       header:(NSDictionary *)header
                       result:(void(^)(NSString *token, LiteResponse *response, NSError *error))result;

/**
 scheme唤起进行绑定操作

 @param url url
 */
- (void)schemeAsk:(NSURL *)url;

@end

