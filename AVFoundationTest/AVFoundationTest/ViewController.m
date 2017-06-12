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
@property (weak, nonatomic) IBOutlet UISlider *playSlider;

@end

@implementation ViewController {
	VodPlayer *player_;
	Float64 duration_;
}

- (void)viewDidLoad
{
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
			[self.playerView setPlayer:player_.player];
		}
	}];
}

- (IBAction)playPauseButton:(id)sender
{
	[player_ play];
}

- (IBAction)playerViewTapGesture:(id)sender
{
	[self togglePlayPauseButton];
}

- (void)togglePlayPauseButton
{
	BOOL isHidden = (self.playPauseButton.alpha == 0.0);
	
	[UIView animateWithDuration:1.0f animations:^{
		
		if (isHidden) {
			self.playPauseButton.alpha = 1.0f;
		} else {
			self.playPauseButton.alpha = 0.0f;
		}
	}];
}

#pragma mark - VodPlayerDelegate

- (void)readyToPlay:(BOOL)isReadyToPlay duration:(Float64)duration
{
	_playPauseButton.enabled = isReadyToPlay;
	duration_ = duration;
}

- (void)didPlayReachEnd
{
	[self.playPauseButton setSelected:NO];
	[self.playSlider setValue:0.0f];
}

- (void)updatePlayTime:(Float64)playTime
{
	if (duration_ > 0) {
		self.playSlider.value = playTime / duration_;
	} else {
		self.playSlider.value = 0.0f;
	}
}

@end
