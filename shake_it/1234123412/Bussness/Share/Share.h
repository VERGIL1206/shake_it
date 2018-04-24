//
//  Share.h
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Share : NSObject

typedef void(^CompleteBlock)(BOOL finished);

+ (void)shareWith:(NSDictionary *)data complete:(CompleteBlock)complete;
+ (void)amazingShareWith:(NSDictionary *)data;
+ (void)handleOpenURL:(NSURL *)url;

@end
