//
//  Listener.h
//  LightKey
//
//  Created by lin on 2017/11/20.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Listener : NSObject

+ (instancetype)shared;

- (void)handelUrl:(NSURL *)url complete:(void(^)(BOOL finished))complete;

- (void)shareHandel:(NSDictionary *)dictionary complete:(void(^)(BOOL finished))complete;

@end
