//
//  ViewController.m
//  AVFoundationTest
//
//  Created by OHSEUNGWOOK on 2017. 6. 8..
//  Copyright © 2017년 OHSEUNGWOOK. All rights reserved.
//

#import "ViewController.h"
#import "VodPlayerView.h"
#import "Util.h"

#define RESET_PLAYTIME_STRING	@"00:00:00"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet VodPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UISlider *playSlider;
@property (weak, nonatomic) IBOutlet UILabel *currentPlayTime;
@property (weak, nonatomic) IBOutlet UILabel *totalPlayTime;

@end

@implementation ViewController {
	
	VodPlayer *player_;
	Float64 duration_;
	BOOL isSeeking_;
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
	[self resetVodPlayer];
	
	player_ = [[VodPlayer alloc] init];
	player_.delegate = self;
	
	[player_ loadPlayer:^(BOOL isLoadPlayer) {
		
		if (isLoadPlayer) {
			[self.playerView setPlayer:player_.player];
		} else {
			NSLog(@"Can't load content..");
		}
	}];
}

- (IBAction)playPauseButton:(id)sender
{
	if (player_ == nil) {
		return;
	}
	
	if ([player_ isVodPlaying]) {
		[player_ pause];
	} else {
		[player_ play];
	}
	
	[self performSelector:@selector(togglePlayPauseButton) withObject:nil afterDelay:2.0];
}

- (IBAction)valueChangeSeek:(id)sender
{
	isSeeking_ = YES;
}

- (IBAction)seekCompleteVodPlay:(UISlider *)sender
{
	if (player_ != nil) {
		
		Float64 duration = [player_ duration];
		
		if (duration > 0.0f) {
			
			CGFloat seekPlayTime = sender.value * duration;
			[player_ seekToTime:seekPlayTime completed:^(BOOL completed) {
				isSeeking_ = NO;
			}];
		}
	}
}

- (IBAction)playerViewTapGesture:(id)sender
{
	[self togglePlayPauseButton];
}

- (void)togglePlayPauseButton
{
	BOOL isHidden = (self.playPauseButton.alpha == 0.0);
	
	[UIView animateWithDuration:0.2f animations:^{
		
		if (isHidden) {
			self.playPauseButton.alpha = 1.0f;
		} else {
			self.playPauseButton.alpha = 0.0f;
		}
	}];
}

- (void)changedPlayPauseButtonStatus:(BOOL)isPlaying
{
	[self.playPauseButton setSelected:isPlaying];
}

- (void)resetVodPlayer
{
	[self changedPlayPauseButtonStatus:NO];
	[player_ seekToTime:0.0f completed:^(BOOL completed) {
		isSeeking_ = NO;
	}];
	
	[self.currentPlayTime setText:RESET_PLAYTIME_STRING];
	[self.totalPlayTime setText:RESET_PLAYTIME_STRING];
}

#pragma mark - VodPlayerDelegate

- (void)readyToPlay:(BOOL)isReadyToPlay duration:(Float64)duration
{
	_playPauseButton.enabled = isReadyToPlay;
	duration_ = duration;
	
	self.totalPlayTime.text = [Util timeFormatted:duration];
}

- (void)updateBufferWithRate:(CGFloat)bufferRate
{
	if (self.playSlider != nil) {
		NSLog(@"bufferRate : %f", bufferRate);
	}
}

- (void)updatePlayTime:(Float64)playTime
{
	if (isSeeking_) {
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		if (duration_ > 0) {
			self.playSlider.value = playTime / duration_;
		} else {
			self.playSlider.value = 0.0f;
		}
		
		self.currentPlayTime.text = [Util timeFormatted:playTime];
	});
}

- (void)changedPlayStatus:(VodPlayStatus)status
{
	[self changedPlayPauseButtonStatus:(status == VodPlayStatus_Playing)];
}

- (void)didPlayReachEnd
{
	[self resetVodPlayer];
}

- (void)failVodPlayerWithErrorType:(VodErrorType)errorType
{
	[self resetVodPlayer];
	NSLog(@"%zd", errorType);
}

@end
