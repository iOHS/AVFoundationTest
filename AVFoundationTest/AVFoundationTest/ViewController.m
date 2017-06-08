//
//  ViewController.m
//  AVFoundationTest
//
//  Created by OHSEUNGWOOK on 2017. 6. 8..
//  Copyright © 2017년 OHSEUNGWOOK. All rights reserved.
//

#import "ViewController.h"
#import "VodPlayerView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet VodPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

@end

@implementation ViewController {
	VodPlayer *player_;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	[self initPlayer];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)initPlayer
{
	player_ = [[VodPlayer alloc] init];
	player_.delegate = self;
	
	[player_ loadPlayer:^(BOOL isLoadPlayer) {
		
		if (isLoadPlayer) {
			NSLog(@"Load Player");
			[self.playerView setPlayer:player_.player];
		}
	}];
}

- (IBAction)playPauseButton:(id)sender
{
	[player_ play];
}

#pragma mark - VodPlayerDelegate
- (void)readyToPlay:(BOOL)isReadyToPlay
{
	_playPauseButton.enabled = isReadyToPlay;
}

@end
