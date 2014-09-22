//
//  SNViewController.m
//  SnapsEmbeddedDemo
//
//  Created by Travis Fischer on 8/18/14.
//  Copyright (c) 2014 Snaps. All rights reserved.
//

#import "SNViewController.h"

@interface SNViewController () <UIWebViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIImageView *_imageView;
@property (nonatomic, strong) UIWebView *_webView;
@property (nonatomic, strong) NSString *_selectedImageURL;

@end

@implementation SNViewController

- (IBAction)launchSnaps:(id)sender
{
    self._webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self._webView.delegate = self;
    [self.view addSubview:self._webView];
    [self._webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://staging.makesnaps.com/rockets"]]];
    
    UILongPressGestureRecognizer *tapAndHold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self._webView addGestureRecognizer:tapAndHold];
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self openContextualMenuAt:[sender locationInView:self._webView]];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *javascriptString = [NSString stringWithFormat:@"setHostApp(\"%@\")", @"ios"];
    [webView stringByEvaluatingJavaScriptFromString:javascriptString];
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.className+=' unselectable';"];
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

- (void)openContextualMenuAt:(CGPoint)pt
{
    // Load the JavaScript code from the Resources and inject it into the web page
    NSString *path = [[NSBundle mainBundle] pathForResource:@"JSTools" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self._webView stringByEvaluatingJavaScriptFromString:jsCode];
    
    // get the Tags at the touch location
    NSString *tags = [self._webView stringByEvaluatingJavaScriptFromString:
                      [NSString stringWithFormat:@"MyAppGetHTMLElementsAtPoint(%i,%i);",(NSInteger)pt.x,(NSInteger)pt.y]];
    
    NSString *tagsSRC = [self._webView stringByEvaluatingJavaScriptFromString:
                         [NSString stringWithFormat:@"MyAppGetLinkSRCAtPoint(%i,%i);",(NSInteger)pt.x,(NSInteger)pt.y]];
    
    self._selectedImageURL = @"";
    
    // If an image was touched, add image-related buttons.
    if ([tags rangeOfString:@",IMG,"].location != NSNotFound && [tagsSRC rangeOfString:@"data:image"].location == NSNotFound) {
        self._selectedImageURL = tagsSRC;
        
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
        if (sheet.title == nil) {
            sheet.title = @"Snap";
        }
        
        [sheet addButtonWithTitle:@"Save Image"];
        [sheet addButtonWithTitle:@"Copy Image"];
        
        [sheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Copy Image"]) {
        [[UIPasteboard generalPasteboard] setString:self._selectedImageURL];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Save Image"]) {
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveImageURL:) object:self._selectedImageURL];
        [queue addOperation:operation];
    }
}

-(void)saveImageURL:(NSString*)url
{
    UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]], nil, nil, nil);
}

@end
