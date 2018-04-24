//
//  DeviceModel.h
//  LightKey
//
//  Created by lin on 2017/11/16.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceModel : NSObject

+ (NSDictionary *)modelling:(id)procy;

@property (nonatomic, copy) NSString *bundle_id;
@property (nonatomic, copy) NSString *bundle_version;
@property (nonatomic, copy) NSString *dsid;
@property (nonatomic, copy) NSString *item_id;
@property (nonatomic, copy) NSString *purchase_date;
@property (nonatomic, assign) BOOL redownload;

@end
