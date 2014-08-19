//
//  SNViewController.m
//  SnapsEmbeddedDemo
//
//  Created by Travis Fischer on 8/18/14.
//  Copyright (c) 2014 Snaps. All rights reserved.
//

#import "SNViewController.h"

@interface SNViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIImageView *_imageView;

@end

@implementation SNViewController

- (IBAction)launchSnaps:(id)sender
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    webView.delegate = self;
    [self.view addSubview:webView];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://staging.makesnaps.com/rockets"]]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *javascriptString = [NSString stringWithFormat:@"setHostApp(\"%@\")", @"ios"];
    [webView stringByEvaluatingJavaScriptFromString:javascriptString];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"load request %@", [request URL]);
    NSString *url = [[request URL] absoluteString];
    NSString *msg = @"app://success?image=";
    
    if ([url hasPrefix:msg]) {
        NSString *imageURL = [url substringFromIndex:msg.length];
        NSLog(@"image: %@", imageURL);
        
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
        UIImage *image = [UIImage imageWithData:imageData];
        
        if (!self._imageView) {
            self._imageView = [[UIImageView alloc] init];
            self._imageView.contentMode = UIViewContentModeScaleAspectFit;
            self._imageView.frame = self.view.bounds;
            [self.view addSubview:self._imageView];
        }
        
        self._imageView.image = image;
        [webView removeFromSuperview];
        return false;
    }
    
    return true;
}

@end
