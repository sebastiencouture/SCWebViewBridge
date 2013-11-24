//
//  SCWebViewBridge.m
//  SCWebViewBridge
//
//  Created by Sebastien Couture on 2013-11-03.
//  Copyright (c) 2013 Sebastien Couture. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//


#import "SCWebViewBridge.h"

@interface SCWebViewBridge()

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) id<UIWebViewDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *receivers;
@property (strong, nonatomic) NSDateFormatter *iso8601DateFormatter;

- (NSString *)call:(NSString *)name;
- (void)processJavascriptCalls;
- (void)callReceiversWithSelector:(SEL)selector arguments:(NSArray *)arguments;

- (void)parseJsonArguments:(NSArray *)arguments;
- (void)stringifyJsonArguments:(NSMutableArray *)arguments;

@end

@implementation SCWebViewBridge

@synthesize webView = _webView;
@synthesize delegate = _delegate;
@synthesize receivers = _receivers;
@synthesize iso8601DateFormatter = _iso8601DateFormatter;

- (id)initWithWebView:(UIWebView *)webView
{
    self = [self init];
    
    if (self)
    {
        self.webView = webView;
        
        self.delegate = webView.delegate;
        self.webView.delegate = self;
        
        self.iso8601DateFormatter = [[NSDateFormatter alloc] init];
        [self.iso8601DateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    }
    
    return self;
}

- (void)loadLocalHtml:(NSString *)path bundle:(NSBundle *)bundle error:(NSError **)error
{
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:path ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:error];
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:bundlePath];
    
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
}

- (void)call:(NSString *)name arguments:firstArg,...
{
    if (!firstArg)
    {
        NSString *functionName = [name stringByAppendingString:@"()"];
        [self call:functionName];
        
        return;
    }
    
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    
    va_list args;
    va_start(args, firstArg);
    
    for (id arg = firstArg; arg != nil; arg = va_arg(args, id))
    {
        [arguments addObject:arg];
    }
    
    va_end(args);
    
    [self stringifyJsonArguments:arguments];
    
    NSMutableDictionary *jsonArguments = [[NSMutableDictionary alloc] init];
    
    [jsonArguments setValue:arguments forKey:@"arguments"];
    
    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonArguments
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData)
    {
        NSLog(@"SCWebViewBridge: failed to serialize arguments to JSON for call '%@', error: %@", name, error);
        return;
    }
    
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsCall = [NSString stringWithFormat:@"SCWebViewBridge.callJavascript(%@, %@)", name, jsonStr];
    
    [self.webView stringByEvaluatingJavaScriptFromString:jsCall];
}

- (void)registerForCalls:(id)receiver
{
    if (!self.receivers)
    {
        self.receivers = [[NSMutableArray alloc] init];
    }
    
    [self.receivers addObject:receiver];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)])
    {
        [self.delegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)])
    {
        [self.delegate webViewDidFinishLoad:webView];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = [request URL];
    NSString *scheme = [[url scheme] lowercaseString];

    if ([scheme isEqualToString:@"scwebviewbridge"])
    {
        [self processJavascriptCalls];
        
        return NO;
    }

    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
    {
        return [self.delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
    {
        [self.delegate webView:webView didFailLoadWithError:error];
    }
}

#pragma mark - private

- (NSString *)call:(NSString *)name
{
    return [self.webView stringByEvaluatingJavaScriptFromString:name];
}

- (void)processJavascriptCalls
{
    NSString *jsCall = [self call:@"SCWebViewBridge.nextCall()"];
    
    while (0 < [jsCall length])
    {
        NSData *data = [jsCall dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSString *name = [json objectForKey:@"name"];
        
        if (name && [name isKindOfClass:[NSString class]])
        {
            NSArray *arguments = [json objectForKey:@"arguments"];
            
            [self parseJsonArguments:arguments];
            
            SEL selector = NSSelectorFromString(name);
            [self callReceiversWithSelector:selector arguments:arguments];
        }
        
        jsCall = [self call:@"SCWebViewBridge.nextCall()"];
    }
}

- (void)callReceiversWithSelector:(SEL)selector arguments:(NSArray *)arguments
{
    if (!self.receivers)
    {
        return;
    }
    
    for (id receiver in self.receivers)
    {
        if (![receiver respondsToSelector:selector])
        {
            continue;
        }
        
        NSMethodSignature* signature = [receiver methodSignatureForSelector:selector];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        
        [invocation setSelector:selector];
        
        for (int index = 0; index < arguments.count; index++)
        {
            id argument = arguments[index];
            
            // target and _cmd are first two arguments
            [invocation setArgument:&argument atIndex:(index + 2)];
        }
        
        [invocation invokeWithTarget:receiver];
    }
}

- (void)parseJsonArguments:(NSMutableArray *)arguments
{
    if (!arguments)
    {
        return;
    }
    
    // only need to worry about NSDate objects since not supported
    // by NSJSONSerialization
    for (int index = arguments.count - 1; 0 <= index; index--)
    {
        id argument = arguments[index];
        
        if ([argument isKindOfClass:[NSMutableArray class]])
        {
            [self parseJsonArguments:argument];
        }
        else if ([argument isKindOfClass:[NSString class]])
        {
            NSDate *date = [self.iso8601DateFormatter dateFromString:argument];
            
            if (date)
            {
                [arguments replaceObjectAtIndex:index withObject:date];
            }
        }
        else
        {
            // do nothing
        }
    }
}

- (void)stringifyJsonArguments:(NSMutableArray *)arguments
{
    if (!arguments)
    {
        return;
    }
    
    // only need to worry about NSDate objects since not supported
    // by NSJSONSerialization
    for (int index = arguments.count - 1; 0 <= index; index--)
    {
        id argument = arguments[index];
        
        if ([argument isKindOfClass:[NSMutableArray class]])
        {
            [self stringifyJsonArguments:argument];
        }
        else if ([argument isKindOfClass:[NSArray class]])
        {
            NSMutableArray *mutable = [NSMutableArray arrayWithArray:argument];
            [arguments replaceObjectAtIndex:index withObject:mutable];
            
            [self stringifyJsonArguments:mutable];
        }
        else if ([argument isKindOfClass:[NSDate class]])
        {
            NSDate *date = (NSDate *)argument;
            uint timeSec = (int)[date timeIntervalSince1970];
            
            NSString *strDate = [NSString stringWithFormat:@"scd:%u", timeSec];
            
            [arguments replaceObjectAtIndex:index withObject:strDate];
        }
        else
        {
            // do nothing
        }
    }
}

@end
