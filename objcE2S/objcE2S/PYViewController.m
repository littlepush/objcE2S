//
//  PYViewController.m
//  objcE2S
//
//  Created by Push Chen on 12/2/13.
//  Copyright (c) 2013 Push Chen. All rights reserved.
//

#import "PYViewController.h"
#import "PYE2S.h"

@interface PYViewController ()

@end

@implementation PYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [PYE2S convert];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
