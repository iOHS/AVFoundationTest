//
//  VodPlayer.m
//  AVFoundationTest
//
//  Created by OHSEUNGWOOK on 2017. 6. 8..
//  Copyright © 2017년 OHSEUNGWOOK. All rights reserved.
//

#import "VodPlayer.h"
#import "VodPlayerView.h"

static const NSString *PlayerItemContext;

#define VOD_SAMPLE @"http://www.ithinknext.com/mydata/board/files/F201308021823010.mp4"
// #define VOD_SAMPLE  @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"

@interface VodPlayer ()
@property (nonatomic) AVPlayerItem *playerItem;

@end

@implementation VodPlayer {
	
	BOOL isLocalFile_;
	
	BOOL isInitPlayer_;
	AVPlayer *avPlayer_;
	AVAsset *asset_;
	
	id playTimeObserver_;
}

- (instancetype)init
{
	if (self = [super init]) {
		
		isLocalFile_ = NO;
		isInitPlayer_ = NO;
		_ispreloadAssetProperty = NO;
		
		// NOTE : 이어폰에서는 소리가 나는데, 단말스피커에서 소리가 나지 않아 추가했더니 소리 남. 확인할것! (170612)
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
		[[AVAudioSession sharedInstance] setActive:YES error: nil];

		
		// self.sampleURL = [[NSBundle mainBundle] URLForResource:@"SampleVideo" withExtension:@"mp4"];
		self.sampleURL = [NSURL URLWithString:VOD_SAMPLE];
	}
	return self;
}

- (void)loadPlayer:(void (^)(BOOL isLoadPlayer))result
{
	/*
	 AVFoundation Programming Guide - Playback
	 - https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html#//apple_ref/doc/uid/TP40010188-CH3-SW2
	 
	 If you don’t know what kind of URL you have, follow these steps:
	 
	 1. Try to initialize an AVURLAsset using the URL, then load its tracks key.
	 If the tracks load successfully, then you create a player item for the asset.
	 
	 2. If 1 fails, create an AVPlayerItem directly from the URL.
	 Observe the player’s status property to determine whether it becomes playable.
	 
	 If either route succeeds, you end up with a player item that you can then associate with a player.
	 */
	
	[self initAsset:^(BOOL isLoaded) {
		
		if (isLoaded) {
			BOOL isPrepareToPlay = [self prepareToPlay];
			result(isPrepareToPlay);
			return;
		}
		
		result(NO);
	}];
}

- (void)initAsset:(void (^)(BOOL isLoaded))result
{
	// urlAsset_ = [[AVURLAsset alloc] initWithURL:self.sampleURL options:nil];
	asset_ = [AVAsset assetWithURL:self.sampleURL];
	NSArray *keys = @[@"tracks"];
	[asset_ loadValuesAsynchronouslyForKeys:keys completionHandler:^{
		
		NSError *error = nil;
		AVKeyValueStatus trackStatus = [asset_ statusOfValueForKey:@"tracks"
																error:&error];
		switch (trackStatus) {
			case AVKeyValueStatusLoaded:
				// NSLog(@"AVKeyValueStatusLoaded");
				break;
			case AVKeyValueStatusFailed:
				// NSLog(@"AVKeyValueStatusFailed");
				break;
			case AVKeyValueStatusCancelled:
				// NSLog(@"AVKeyValueStatusCancelled");
				break;
			default:
				// NSLog(@"Etc : %zd", trackStatus);
				break;
		}
		
		result(trackStatus == AVKeyValueStatusLoaded);
		
	}];
}

- (BOOL)prepareToPlay
{
	if (asset_ == nil) {
		return NO;
	}
	
	isLocalFile_ = [self.sampleURL isFileURL];
	
	if (_ispreloadAssetProperty) {
		
		/*
		 * NOTE : When the player item is ready to play, those asset properties will have been loaded and are ready for use.
		 * https://developer.apple.com/documentation/avfoundation/avplayeritem?language=objc - Overview
		 */
		
		NSArray *assetKeys = @[@"playable", @"hasProtectedContent"];
		
		self.playerItem = [AVPlayerItem playerItemWithAsset:asset_ automaticallyLoadedAssetKeys:assetKeys];
		
	} else {
		
		if (isLocalFile_) {
			self.playerItem = [AVPlayerItem playerItemWithAsset:asset_];
		} else {
			self.playerItem = [AVPlayerItem playerItemWithURL:self.sampleURL];
		}
	}
	
	if (self.playerItem == nil) {
		return NO;
	}
	
	// Register as an observer of the player item's status property
	NSKeyValueObservingOptions options = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
	[self.playerItem addObserver:self
					  forKeyPath:@"status"
						 options:options
						 context:&PlayerItemContext];
	
	// Associate the player item with the player
	avPlayer_ = [AVPlayer playerWithPlayerItem:self.playerItem];
	
	
	if (isInitPlayer_ == NO) {
		
		isInitPlayer_ = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playerItemDidReachEnd:)
													 name:AVPlayerItemDidPlayToEndTimeNotification
												   object:[avPlayer_ currentItem]];
		
		__block VodPlayer *vodPlayerObject = self;
		CMTime interval = CMTimeMakeWithSeconds(1.0, NSEC_PER_SEC); // 1 second
		playTimeObserver_ = [avPlayer_ addPeriodicTimeObserverForInterval:interval
																	queue:NULL usingBlock:^(CMTime time) {
																		
																		
																		NSLog(@"isPlaying : %d", [vodPlayerObject isPlaying]);
																		
																		if ([vodPlayerObject.delegate respondsToSelector:@selector(updatePlayTime:isPlaying:)]) {
																			[vodPlayerObject.delegate updatePlayTime:CMTimeGetSeconds(time) isPlaying:[vodPlayerObject isPlaying]];
																		}
																	}];
	}
	
	
	return YES;
}

- (void)initAssetWithURL
{
	self.playerItem = [AVPlayerItem playerItemWithURL:self.sampleURL];
	
	if (self.playerItem == nil) {
		return;
	}
}

- (void)play
{
	if (avPlayer_ != nil) {
		[avPlayer_ play];
	}
}

- (void)pause
{
	if (avPlayer_ != nil) {
		[avPlayer_ pause];
	}
}


- (AVPlayer *)player
{
	return avPlayer_;
}

- (BOOL)isPlaying
{
	if (avPlayer_ != nil) {
		return (avPlayer_.rate > 0.0);
	}
	
	return NO;
}

- (void)resetPlayer
{
	[self pause];
}

#pragma mark - VodPlayerDelegate

- (BOOL)readyToPlay
{
	BOOL isReadyToPlay = NO;
	if ((avPlayer_.currentItem != nil) &&
		([avPlayer_.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
		isReadyToPlay = YES;
	}
	
	return isReadyToPlay;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	[self resetPlayer];
	
	if ([self.delegate respondsToSelector:@selector(didPlayReachEnd)]) {
		[self.delegate didPlayReachEnd];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context
{
	
	/*
	 *	You should call this method before associating the player item with the player to make sure you capture  all state changes to the item’s status.
	 *	This method is invoked whenever the status changes giving you the chance to take some action in response
	 */
	
	if (context != &PlayerItemContext) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}
	
	if ([keyPath isEqualToString:@"status"]) {
		
		AVPlayerItemStatus status = AVPlayerItemStatusUnknown;
		// Get the status change from the change dictionary
		NSNumber *statusNumber = change[NSKeyValueChangeNewKey];
		
		NSLog(@"status : %zd", [statusNumber integerValue]);
		
		if ([statusNumber isKindOfClass:[NSNumber class]]) {
			
			status = statusNumber.integerValue;
			dispatch_async(dispatch_get_main_queue(),^{
				if ([self.delegate respondsToSelector:@selector(readyToPlay:duration:)]) {
					[self.delegate readyToPlay:(status == AVPlayerItemStatusReadyToPlay) duration:CMTimeGetSeconds(avPlayer_.currentItem.duration)];
				}
			});
		}
	}
}

@end
