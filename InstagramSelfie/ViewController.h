//
//  ViewController.h
//  InstagramSelfie
//
//  Created by Kunal Shah on 23/10/14.
//  Copyright (c) 2014 Kunal Shah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Defines.h"

@interface ViewController : UIViewController

@property(nonatomic, weak) IBOutlet UIWebView *objInstagramWebView;
@property(nonatomic, weak) IBOutlet UIActivityIndicatorView *objActivityIndicator;

-(IBAction)pushCollectionVC:(id)sender;

@end
