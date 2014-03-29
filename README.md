# SPLMessageLogger

[![Version](http://cocoapod-badges.herokuapp.com/v/SPLMessageLogger/badge.png)](http://cocoadocs.org/docsets/SPLMessageLogger)
[![Platform](http://cocoapod-badges.herokuapp.com/p/SPLMessageLogger/badge.png)](http://cocoadocs.org/docsets/SPLMessageLogger)
[![License Badge](https://go-shields.herokuapp.com/license-MIT-blue.png)](https://go-shields.herokuapp.com/license-MIT-blue.png)

SPLMessageLogger can intercept and log all objc messages right to your console:

```
-> <UINavigationBar:0x167a9960>: -[UIView setCenter:NSPoint: {384, 42}]
=> void
-> <UIView:0x167b7e40>: -[UIView setCenter:NSPoint: {384, 512}]
=> void
-> <UIImageView:0x167c56c0>: -[UIView setCenter:NSPoint: {0, 0}]
=> void
```

## Installation

SPLMessageLogger is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

``` ruby
pod "SPLMessageLogger"
```

## Usage

SPLMessageLogger can intercept and log all objc messages. It therefore defines the following interface on `NSObject`

``` objc
@interface NSObject (SPLMessageLogger)

+ (instancetype)messageLogger;

@end
```

where the messageLogger records every message it receives and hooks into the runtime to intercept and log these recorded messages. Let's take a look at an example:

``` objc
@interface SPLView : UIView

- (CGPoint)setCenter:(CGPoint)center atIndex:(NSInteger)index forObject:(id)object;

@end

@implementation SPLView

- (CGPoint)setCenter:(CGPoint)center atIndex:(NSInteger)index forObject:(id)object
{
    [super setCenter:center];
    return self.center;
}

@end
```

To now intercept and log all messages to `-[SPLView setCenter:atIndex:forObject:]` and `-[UIView setCenter:]`, simply run

``` objc
SPLView *firstMessageLogger = [SPLView messageLogger];
[firstMessageLogger setCenter:CGPointZero atIndex:0 forObject:nil];

UIView *secondMessageLogger = [UIView messageLogger];
[secondMessageLogger setCenter:CGPointZero];
```

At runtime, this can result in the following output

```
-> <SPLView:0x166c41f0>: -[SPLView setCenter:NSPoint: {0.5, 0.5} atIndex:5 forObject:<ICAppDelegate: 0x166b0570>]
--> <SPLView:0x166c41f0>: -[UIView setCenter:NSPoint: {0.5, 0.5}]
==> void
=> NSPoint: {0.5, 0.5}
-> <SPLView:0x166c41f0>: -[UIView setCenter:NSPoint: {0.5, 0.5}]
=> void
-> <UINavigationBar:0x167a9960>: -[UIView setCenter:NSPoint: {384, 42}]
=> void
-> <UIView:0x167b7e40>: -[UIView setCenter:NSPoint: {384, 512}]
=> void
-> <UIImageView:0x167c56c0>: -[UIView setCenter:NSPoint: {0, 0}]
=> void
```

## How it works

### Message forwarding

For this library, I have written a custom trampoline (you can read about trampolines [here](http://landonf.bikemonkey.org/2011/04/index.html)) which can forward any objc message to a new selector.

``` objc
IMP imp_implementationForwardingToSelector(SEL forwardingSelector, BOOL returnsAStructValue);
```

Here is an example

``` objc
IMP forwardingImplementation = imp_implementationForwardingToSelector(@selector(setCenter:), NO);
class_addMethod([UIView class], @selector(thisSetCenterDoesNotExistYet:), forwardingImplementation, typeEndoding);
```

and suddenly every instance of `UIView` responds to `-[UIView thisSetCenterDoesNotExistYet:]` and forwards this message to `-[UIView setCenter:]`. If you would like some more information about trampolines and maybe a blog post like `Writing custom trampolines for beginners and all the pitfalls`, hit me up on [Twitter](http://twitter.com/oletterer).

### Runtime hacking

`+[NSObject messageLogger]` returns an instance of `SPLMessageLoggerRecorder` which implements `-[NSObject methodSignatureForSelector:]` and then uses `-[NSObject forwardInvocation:]` (similar to what UIAppearance is using) as an entry point to hook into the runtime. The runtime hook is probably best explained with the example from above:

``` objc
SPLView *firstMessageLogger = [SPLView messageLogger];
[firstMessageLogger setCenter:CGPointZero atIndex:0 forObject:nil];
```

Once `firstMessageLogger` receives the `setCenter:atIndex:forObject:` message, it does the following things:

- Store the original implementation of `-[SPLView setCenter:atIndex:forObject:]` at the new location `-[SPLView __SPLMessageLogger_original_SPLView_setCenter:atIndex:forObject:]`
- Replace the implementation of `-[SPLView setCenter:atIndex:forObject:]` with a new implementation obtained by `imp_implementationForwardingToSelector` which forwards to `__SPLMessageLogger_SPLView_setCenter:atIndex:forObject:`.

The trick here is that no instance every is responding to the forwarded `-[SPLView __SPLMessageLogger_SPLView_setCenter:atIndex:forObject:]`. In these cases, the objc runtime is asking `-[NSObject forwardingTargetForSelector:]`, which for this selector returns an instance of the actual `SPLMessageLogger` class. This instance then receives the message `__SPLMessageLogger_SPLView_setCenter:atIndex:forObject:`. It implements `-[NSObject methodSignatureForSelector:]` and then uses `-[NSObject forwardInvocation:]` to log the invocation and then forwards the invocation back to the original object to the original implementation:

```
-[SPLView setCenter:] // gets forwarded
↓
-[SPLView __SPLMessageLogger_SPLView_setCenter:atIndex:forObject:] // no implementation is found
↓
-[SPLView forwardingTargetForSelector:] // return an instance of SPLMessageLogger
↓
-[SPLMessageLogger methodSignatureForSelector:] // lets the runtime construct an invocation
↓
-[SPLMessageLogger forwardInvocation:]
// 1) log the invocation
// 2) forward invocation
↓
--->	`-[SPLView __SPLMessageLogger_original_SPLView_setCenter:atIndex:forObject:]` // execute original implementation
<---	`-[SPLView __SPLMessageLogger_original_SPLView_setCenter:atIndex:forObject:]`
// 3) log return argument of invocation
```

## Limitations

This approach uses a custom trampoline written in raw assembly which is currently only available on i386, armv7, armv7s and arm64.

## Author

Oliver Letterer

- http://github.com/OliverLetterer
- http://twitter.com/oletterer
- oliver.letterer@gmail.com

## License

SPLMessageLogger is available under the MIT license. See the LICENSE file for more info.

