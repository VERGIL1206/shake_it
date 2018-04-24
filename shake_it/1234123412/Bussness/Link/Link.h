//
//  Link.h
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Link : NSObject
+ (instancetype)shared;
- (BOOL)checkNetwork;
- (void)beginWork:(BOOL )re showShare:(BOOL)show;
@end
