//
//  Ytrace.m
//  Ytrace
//
//  Created by John Holdsworth on 26/03/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "Ytrace.h"

#import <objc/runtime.h>
#import "SPLMessageLogger.h"

@implementation NSRegularExpression(SPLRegularExpression)

- (BOOL)matches:(NSString *)name
{
    return [self rangeOfFirstMatchInString:name options:0 range:NSMakeRange(0, [name length])].location != NSNotFound;
}

@end

@implementation Ytrace

+ (NSRegularExpression *)regexp:(NSString *)pattern
{
    if ( !pattern )
        return nil;
    NSError *error = nil;
    NSRegularExpression *regexp = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:&error];
    if ( error )
        NSLog( @"Xtrace: filter compilation error: %@, in pattern: \"%@\"", [error localizedDescription], pattern );
    return regexp;
}

+ (void)traceClass:(Class)aClass levels:(int)levels
{
    // class methods??
    //Class metaClass = object_getClass(aClass);
    //[self traceClass:metaClass mtype:"+" levels:levels];
    [self traceClass:aClass mtype:"" levels:levels];
}

static NSRegularExpression *selectorExclusions;

+ (void)traceClass:(Class)aClass mtype:(const char *)mtype levels:(int)levels
{
    if ( !selectorExclusions )
        selectorExclusions = [self regexp:@"(WithObjects(AndKeys)?|Format):$"];

    for ( int l=0 ; l<levels ; l++ ) {
        unsigned mc = 0;
        Method *methods = class_copyMethodList(aClass, &mc);

        for( unsigned i=0; methods && i<mc; i++ ) {
            SEL name = method_getName(methods[i]);

            if ( [selectorExclusions matches:NSStringFromSelector(name)] )
                NSLog( @"Ytrace: Excluding %s", sel_getName(name) );
            else if ( [class_getSuperclass(aClass) instancesRespondToSelector:name] )
                ;//NSLog( @"Ytrace: Skipping possible message to super %s", sel_getName(name) );
            else
                spl_classLogSelector(aClass, name);
        }

        free( methods );

        aClass = class_getSuperclass(aClass);
        if ( aClass == [NSObject class] || aClass == object_getClass([NSObject class]) )
            break;
    }
}

+ (void)traceClassPattern:(NSString *)pattern excluding:(NSString *)exclusions
{
    NSRegularExpression *include = [self regexp:pattern], *exclude = [self regexp:exclusions];

    unsigned ccount;
    Class *classes = objc_copyClassList( &ccount );
    for ( unsigned i=0 ; i<ccount ; i++ ) {
        NSString *className = [NSString stringWithUTF8String:class_getName(classes[i])];
        if ( [include matches:className] && (!exclude || ![exclude matches:className]) )
            [self traceClass:classes[i] levels:1];
    }

    free( classes );
}

@end
