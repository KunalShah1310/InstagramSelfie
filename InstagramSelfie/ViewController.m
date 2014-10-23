//
//  ViewController.m
//  InstagramSelfie
//
//  Created by Kunal Shah on 23/10/14.
//  Copyright (c) 2014 Kunal Shah. All rights reserved.
//

#import "ViewController.h"
#import "NSDictionary+UrlEncoding.h"

@interface ViewController ()
    @property(nonatomic, strong) NSURLConnection *tokenRequestConnection;
    @property(nonatomic, strong) NSMutableData *data;
@end

@implementation ViewController
@synthesize tokenRequestConnection, data;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.navigationController setNavigationBarHidden:YES];
    self.tokenRequestConnection = nil;
    self.data = [NSMutableData data];
    [self authorize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)pushCollectionVC:(id)sender
{
    [self performSegueWithIdentifier:@"collectionPush" sender:nil];
}


-(void) authorize
{
    //See http://instagram.com/developer/authentication/ for more details.
    
    NSString *scopeStr = @"scope=likes+comments+relationships";
    
    NSString *url = [NSString stringWithFormat:@"https://api.instagram.com/oauth/authorize/?client_id=%@&display=touch&%@&redirect_uri=http://www.charterglobal.com&response_type=code", INSTAGRAM_CLIENT_ID, scopeStr];
    
    [self.objActivityIndicator setHidden:NO];
    [self.objActivityIndicator startAnimating];
    [self.objInstagramWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.objActivityIndicator stopAnimating];
    self.objActivityIndicator.hidden = TRUE;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[self.objInstagramWebView stopLoading];
    [self.objActivityIndicator stopAnimating];
    self.objActivityIndicator.hidden = TRUE;
	if([error code] == -1009)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot open the page because it is not connected to the Internet." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *responseURL = [request.URL absoluteString];
    
    NSString *urlCallbackPrefix = [NSString stringWithFormat:@"%@/?code=", INSTAGRAM_CALLBACK_BASE];
    
    //We received the code, now request the auth token from Instagram.
    if([responseURL hasPrefix:urlCallbackPrefix])
    {
        NSString *authToken = [responseURL substringFromIndex:[urlCallbackPrefix length]];
        
        NSURL *url = [NSURL URLWithString:@"https://api.instagram.com/oauth/access_token"];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys:authToken, @"code", INSTAGRAM_CALLBACK_BASE, @"redirect_uri", @"authorization_code", @"grant_type",  INSTAGRAM_CLIENT_ID, @"client_id",  INSTAGRAM_CLIENT_SECRET, @"client_secret", nil];
        
        NSString *paramString = [paramDict urlEncodedString];
        
        NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
        
        [request setHTTPMethod:@"POST"];
        [request addValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@",charset] forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[paramString dataUsingEncoding:NSUTF8StringEncoding]];
        
        self.tokenRequestConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        [self.tokenRequestConnection start];
        
        [self.objActivityIndicator stopAnimating];
        self.objActivityIndicator.hidden = TRUE;
        
        return NO;
    }
    
	return YES;
}

#pragma Mark NSURLConnection delegates

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)_data
{
    [self.data appendData:_data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.data setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *jsonError = nil;
    id jsonData = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&jsonError];
    if(jsonData && [NSJSONSerialization isValidJSONObject:jsonData])
    {
        NSString *accesstoken = [jsonData objectForKey:@"access_token"];
        if(accesstoken)
        {
            [self didAuth:accesstoken];
            return;
        }
    }
    
    [self didAuth:nil];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    return request;
}

//This is our authentication delegate. When the user logs in, and Instagram sends us our auth token, we receive that here.
-(void) didAuth:(NSString*)token
{
    if(!token)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to request token."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    //  As a test, we'll request a list of popular Instagram photos.
    
    //  NSString *popularURLString = [NSString stringWithFormat:@"https://api.instagram.com/v1/media/popular?access_token=%@", token];
    
    NSString *popularURLString = [NSString stringWithFormat:@"https://api.instagram.com/v1/tags/selfie/media/recent?access_token=%@", token];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:popularURLString]];
    request.HTTPMethod = @"GET";
    NSOperationQueue *theQ = [NSOperationQueue new];
    
//    NSData *instData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    [NSURLConnection sendAsynchronousRequest:request queue:theQ
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               
                               
                               NSError *err;
                               id val = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
                               NSMutableDictionary *selfieDict = val;
                               
                               NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:selfieDict];
                               [[NSUserDefaults standardUserDefaults] setObject:encodedObject forKey:@"instData"];
                               [[NSUserDefaults standardUserDefaults] synchronize];
                               
                              
                               if(!err && !error && val && [NSJSONSerialization isValidJSONObject:val])
                               {
                                   NSArray *data = [val objectForKey:@"data"];
                                   
                                   dispatch_sync(dispatch_get_main_queue(), ^{
                                       
                                       if(!data)
                                       {
                                           UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to request perform request."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                           [alertView show];
                                       } else
                                       {
                                           
                                           UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:[NSString stringWithFormat:@"Successfully retrieved popular photos!"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                           [alertView show];
                                           [self performSegueWithIdentifier:@"collectionPush" sender:nil];
                                       }
                                   });
                               }
                           }];
}


@end
