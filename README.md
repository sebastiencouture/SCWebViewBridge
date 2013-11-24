SCWebViewBridge
===============

SCWebViewBridge helps make Javascript calls to Objective-C and Objective-C calls to Javascript easier. Supports passing primitive types. iOS 5 and above supported.


## Example Usage

* Calling Objective-C from Javascript

``` javascript
SCWebViewBridge.call( "methodSimple" );

SCWebViewBridge.call( "methodComplex:array:", new Date(), [ "Stuff, youâ€™ll need to blah blah Person detail view & engagement[ ],", 4.2 ]  );
```

Register for calls from Javascript

``` objective-c
[self.webViewBridge registerForCalls:self];
```

* Calling Javascript from Objective-C

``` objective-c
[self.webViewBridge call:@"testSimple" arguments:nil];

[self.webViewBridge call:@"NamespaceTest.testComplex" arguments:[NSDate date], @"TEST", nil];
```

* Load local HTML file

``` objective-c
self.webViewBridge = [[SCWebViewBridge alloc] initWithWebView:self.webView];

[self.webViewBridge loadLocalHtml:@"sample" bundle:[NSBundle mainBundle] error:nil];
```


## Supported Primitive Types

Javascript         | Objective-C
-------------------|-------------
Number             | [`NSNumber`][NSNumber]
String             | [`NSString`][NSString]
Date               | [`NSDate`][NSDate]
`null`             | [`NSNull`][NSNull]
`true` and `false` | [`NSNumber`][NSNumber]
Array              | [`NSArray`][NSArray]
Object             | [`NSDictionary`][NSDictionary]


## How to Use

1. Copy SCWebViewBridge folder into your project
2. Include SCWebViewBridge.js in HTML/JS


## License

SCWebViewBridge, and all the accompanying source code, is released under the MIT license