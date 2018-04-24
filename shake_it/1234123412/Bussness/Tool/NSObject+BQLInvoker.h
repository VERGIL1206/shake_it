//
//  NSObject+BQLInvoker.h
//  BQLNSInvocationStudy
//
//  Created by lin on 2017/9/6.
//  Copyright © 2017年 biqinglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BQLInvokerArgumentType) {
    BQLInvokerArgumentTypeUnknown             = 0,
    BQLInvokerArgumentTypeChar,
    BQLInvokerArgumentTypeInt,
    BQLInvokerArgumentTypeShort,
    BQLInvokerArgumentTypeLong,
    BQLInvokerArgumentTypeLongLong,
    BQLInvokerArgumentTypeUnsignedChar,
    BQLInvokerArgumentTypeUnsignedInt,
    BQLInvokerArgumentTypeUnsignedShort,
    BQLInvokerArgumentTypeUnsignedLong,
    BQLInvokerArgumentTypeUnsignedLongLong,
    BQLInvokerArgumentTypeFloat,
    BQLInvokerArgumentTypeDouble,
    BQLInvokerArgumentTypeBool,
    BQLInvokerArgumentTypeVoid,
    BQLInvokerArgumentTypeCharacterString,
    BQLInvokerArgumentTypeCGPoint,
    BQLInvokerArgumentTypeCGSize,
    BQLInvokerArgumentTypeCGRect,
    BQLInvokerArgumentTypeUIEdgeInsets,
    BQLInvokerArgumentTypeObject,
    BQLInvokerArgumentTypeClass
};

@interface NSObject (BQLInvoker)

/**
 无参 有返回值则返回，无返回值则返回nil
 
 @param selector 方法名
 
 @return 返回值
 */
- (id )bql_invoke:(NSString *)selector;

/**
 有参 有返回值则返回，无返回值则返回nil
 
 @param selector 方法名
 @param arguments 参数(顺序要一致)
 
 @return 返回值
 */
- (id )bql_invoke:(NSString *)selector arguments:(NSArray *)arguments;

/**
 无参 有返回值则返回，无返回值则返回nil

 @param selector 方法名

 @return 返回值
 */
- (id )bql_invokeMethod:(NSString *)selector;

/**
 有参 有返回值则返回，无返回值则返回nil

 @param selector  方法名
 @param arguments 参数

 @return 返回值
 */
- (id )bql_invokeMethod:(NSString *)selector arguments:(NSArray *)arguments;

@end


