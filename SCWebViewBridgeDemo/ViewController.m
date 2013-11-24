//
//  ViewController.m
//  SCWebViewBridgeDemo
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

#import "ViewController.h"

#import "SCWebViewBridge.h"

@interface ViewController ()

@property (strong, nonatomic) SCWebViewBridge* webViewBridge;

- (void)displayAlert:(NSString *)message;

@end

@implementation ViewController

@synthesize webViewBridge = _webViewBridge;

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.dataDetectorTypes = UIDataDetectorTypeLink;
    
    self.webViewBridge = [[SCWebViewBridge alloc] initWithWebView:self.webView];
    
    [self.webViewBridge registerForCalls:self];
    [self.webViewBridge loadLocalHtml:@"sample" bundle:[NSBundle mainBundle] error:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)methodSimple
{
    [self displayAlert:@"methodSimple called"];
}

- (void)methodComplex:(NSDate *)date array:(NSArray *)array
{
    [self displayAlert:@"methodComplex called"];
}

#pragma - action handlers

- (IBAction)testSimpleJavascriptHandler:(id)sender
{
    [self.webViewBridge call:@"testSimple" arguments:nil];
}

- (IBAction)testComplexJavascriptionHandler:(id)sender
{
    [self.webViewBridge call:@"NamespaceTest.testComplex" arguments:[NSDate date], @"TEST", nil];
}

#pragma mark - private

- (void)displayAlert:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Javascript -> Obj-C" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
