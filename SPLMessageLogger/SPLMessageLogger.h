//
//  SPLMessageLogger.h
//  SPLMessageLogger
//
//  Created by Oliver Letterer on 22.03.14.
//  Copyright 2014 Sparrowlabs. All rights reserved.
//

void spl_classLogSelector(Class class, SEL selector);



@interface NSObject (SPLMessageLogger)

+ (instancetype)messageLogger;

@end

