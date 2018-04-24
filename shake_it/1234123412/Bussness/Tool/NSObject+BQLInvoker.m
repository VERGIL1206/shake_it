//
//  NSObject+BQLInvoker.m
//  BQLNSInvocationStudy
//
//  Created by lin on 2017/9/6.
//  Copyright © 2017年 biqinglin. All rights reserved.
//

#import "NSObject+BQLInvoker.h"

@implementation NSObject (BQLInvoker)

- (id )bql_invoke:(NSString *)selector {
    
    return bqlBase_invoke(self, selector, nil, NO);
}

- (id )bql_invoke:(NSString *)selector arguments:(NSArray *)arguments {
    
    NSAssert(arguments == nil || [arguments isKindOfClass:[NSArray class]], @"please set a correct arguments");
    return bqlBase_invoke(self, selector, arguments, NO);
}

- (id )bql_invokeMethod:(NSString *)selector {
    
    return bqlBase_invoke(self, selector, nil, YES);
}

- (id )bql_invokeMethod:(NSString *)selector arguments:(NSArray *)arguments {
    
    return bqlBase_invoke(self, selector, arguments, YES);
}

id bqlBase_invoke(id class, NSString *selector, NSArray *arguments, BOOL method) {
    
    SEL sel = NSSelectorFromString(selector);
    NSMethodSignature *signature = nil;
    if(method) {
        signature = [[class class] methodSignatureForSelector:sel];
    }
    else {
        signature = [[class class] instanceMethodSignatureForSelector:sel];
    }
    if(!signature) return nil;

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = class;
    invocation.selector = sel;
    if(arguments) {
        [arguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            // 索引从2开始,0、1已被占用,分别是:target、selector
            NSUInteger index = idx + 2;
            //[invocation setArgument:&obj atIndex:index];
            setArgument(signature, invocation, obj, index);
        }];
    }
    [invocation invoke];
    
    // 返回值类型 '@'是id类型,'v'为无返回,其他可视为基本数值类型(更详细的类型请查阅资料)
    const char *returnType = [signature methodReturnType];
    id result = nil;
    switch (returnType[0]) {
        case '@': {
            id __unsafe_unretained _result = nil;
            [invocation getReturnValue:&_result];
            result = _result;
        }
            break;
        case 'v': {
            return nil;
        }
            break;
            
        default: {
            NSInteger _result = 0;
            [invocation getReturnValue:&_result];
            result = @(_result);
        }
            break;
    }
    return result;
}

void setArgument(NSMethodSignature *signature, NSInvocation *invocation, id argument, NSUInteger index) {
    
    const char *encodetype = [signature getArgumentTypeAtIndex:index];
    BQLInvokerArgumentType type = argumentTypeWithType(encodetype);
    switch (type) {
        case BQLInvokerArgumentTypeChar: {
            char value = [argument charValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeInt: {
            int value = [argument intValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeShort: {
            short value = [argument shortValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeLong: {
            long value = [argument longValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeLongLong: {
            long long value = [argument longLongValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeUnsignedChar: {
            unsigned char value = [argument unsignedCharValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeUnsignedInt: {
            unsigned int value = [argument unsignedIntValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeUnsignedShort: {
            unsigned short value = [argument unsignedShortValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeUnsignedLong: {
            unsigned long value = [argument unsignedLongValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeUnsignedLongLong: {
            unsigned long long value = [argument unsignedLongLongValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeFloat: {
            float value = [argument floatValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeDouble: {
            double value = [argument doubleValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeBool: {
            BOOL value = [argument boolValue];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeVoid: {
            
        } break;
        case BQLInvokerArgumentTypeCharacterString: {
            const char *value = [argument UTF8String];
            [invocation setArgument:&value atIndex:index];
        } break;
        case BQLInvokerArgumentTypeObject: {
            [invocation setArgument:&argument atIndex:index];
        } break;
        case BQLInvokerArgumentTypeClass: {
            Class value = [argument class];
            [invocation setArgument:&value atIndex:index];
        } break;
            
        default: break;
    }
}

BQLInvokerArgumentType argumentTypeWithType(const char *type) {
    
    if (strcmp(type, @encode(char)) == 0) {
        return BQLInvokerArgumentTypeChar;
    }
    else if (strcmp(type, @encode(int)) == 0) {
        return BQLInvokerArgumentTypeInt;
    }
    else if (strcmp(type, @encode(short)) == 0) {
        return BQLInvokerArgumentTypeShort;
    }
    else if (strcmp(type, @encode(long)) == 0) {
        return BQLInvokerArgumentTypeLong;
    }
    else if (strcmp(type, @encode(long long)) == 0) {
        return BQLInvokerArgumentTypeLongLong;
    }
    else if (strcmp(type, @encode(unsigned char)) == 0) {
        return BQLInvokerArgumentTypeUnsignedChar;
    }
    else if (strcmp(type, @encode(unsigned int)) == 0) {
        return BQLInvokerArgumentTypeUnsignedInt;
    }
    else if (strcmp(type, @encode(unsigned short)) == 0) {
        return BQLInvokerArgumentTypeUnsignedShort;
    }
    else if (strcmp(type, @encode(unsigned long)) == 0) {
        return BQLInvokerArgumentTypeUnsignedLong;
    }
    else if (strcmp(type, @encode(unsigned long long)) == 0) {
        return BQLInvokerArgumentTypeUnsignedLongLong;
    }
    else if (strcmp(type, @encode(float)) == 0) {
        return BQLInvokerArgumentTypeFloat;
    }
    else if (strcmp(type, @encode(double)) == 0) {
        return BQLInvokerArgumentTypeDouble;
    }
    else if (strcmp(type, @encode(BOOL)) == 0) {
        return BQLInvokerArgumentTypeBool;
    }
    else if (strcmp(type, @encode(void)) == 0) {
        return BQLInvokerArgumentTypeVoid;
    }
    else if (strcmp(type, @encode(char *)) == 0) {
        return BQLInvokerArgumentTypeCharacterString;
    }
    else if (strcmp(type, @encode(id)) == 0) {
        return BQLInvokerArgumentTypeObject;
    }
    else if (strcmp(type, @encode(Class)) == 0) {
        return BQLInvokerArgumentTypeClass;
    }
    else if (strcmp(type, @encode(CGPoint)) == 0) {
        return BQLInvokerArgumentTypeCGPoint;
    }
    else if (strcmp(type, @encode(CGSize)) == 0) {
        return BQLInvokerArgumentTypeCGSize;
    }
    else if (strcmp(type, @encode(CGRect)) == 0) {
        return BQLInvokerArgumentTypeCGRect;
    }
    else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
        return BQLInvokerArgumentTypeUIEdgeInsets;
    }
    else {
        return BQLInvokerArgumentTypeUnknown;
    }
}

@end
