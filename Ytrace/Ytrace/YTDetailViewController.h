//
//  SPLDetailViewController.h
//  Ytrace
//
//  Created by John Holdsworth on 26/03/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YTDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
