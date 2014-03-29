//
//  Ytrace.h
//  Ytrace
//
//  Created by John Holdsworth on 26/03/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//
//  "Xtrace" style interface to SPLMessageLogger
//  viz: https://github.com/johnno1962/Xtrace
//

#import <Foundation/Foundation.h>

@interface Ytrace : NSObject

// be careful not to trace the same class twice!
+ (void)traceClass:(Class)aClass levels:(int)levels;
+ (void)traceClassPattern:(NSString *)pattern excluding:(NSString *)exclusions;

@end
