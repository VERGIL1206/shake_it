//
//  ModelHandle.h
//  LightKey
//
//  Created by Musick on 2017/11/21.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelHandle : NSObject

+ (instancetype)handled;

- (BOOL )checkIDFAThenSendModel:(BOOL)send;


@end
