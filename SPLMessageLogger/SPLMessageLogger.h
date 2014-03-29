//
//  SPLMessageLogger.h
//  cashier
//
//  Created by Oliver Letterer on 22.03.14.
//  Copyright 2014 Sparrowlabs. All rights reserved.
//

IMP imp_implementationForwardingToSelector(SEL forwardingSelector, BOOL returnsAStructValue);

void spl_classLogSelector(Class class, SEL selector);


@interface NSObject (SPLMessageLogger)

+ (instancetype)messageLogger;

@end

