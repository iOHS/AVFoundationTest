//
//  VodPlayer.m
//  AVFoundationTest
//
//  Created by OHSEUNGWOOK on 2017. 6. 8..
//  Copyright © 2017년 OHSEUNGWOOK. All rights reserved.
//

#import "VodPlayer.h"
#import "VodPlayerView.h"

static const NSString *ItemStatusContext;

// #define VOD_SAMPLE @"http://www.ithinknext.com/mydata/board/files/F201308021823010.mp4
#define VOD_SAMPLE  @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"

@interface VodPlayer ()
@property (nonatomic) AVPlayerItem *playerItem;

@end

@implementation VodPlayer {
	
	BOOL isLocalFile_;
	
	AVPlayer *avPlayer_;
	AVURLAsset *urlAsset_;
}

- (instancetype)init
{
	if (self = [super init]) {
		isLocalFile_ = NO;
		
		self.sampleURL = [[NSBundle mainBundle] URLForResource:@"SampleVideo" withExtension:@"mp4"];
		//self.sampleURL = [NSURL URLWithString:VOD_SAMPLE];
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
	
	__block BOOL isLoadPlayer = NO;
	[self initAsset:^(BOOL isLocalFileLoad) {
		
		if ([self makePlayerItem]) {
			isLoadPlayer = [self initPlayer];
			result(isLoadPlayer);
		}
		
		result(NO);
	}];
}

- (void)initAsset:(void (^)(BOOL isLocalFileLoad))result
{
	urlAsset_ = [[AVURLAsset alloc] initWithURL:self.sampleURL options:nil];
	NSArray *keys = @[@"tracks"];
	[urlAsset_ loadValuesAsynchronouslyForKeys:keys completionHandler:^{
		
		NSError *error = nil;
		AVKeyValueStatus trackStatus = [urlAsset_ statusOfValueForKey:@"tracks"
																error:&error];
		switch (trackStatus) {
			case AVKeyValueStatusLoaded:
				NSLog(@"AVKeyValueStatusLoaded");
				break;
			case AVKeyValueStatusFailed:
				NSLog(@"AVKeyValueStatusFailed");
				break;
			case AVKeyValueStatusCancelled:
				NSLog(@"AVKeyValueStatusCancelled");
				break;
			default:
				NSLog(@"Etc : %zd", trackStatus);
				break;
		}
		
		result(trackStatus == AVKeyValueStatusLoaded);
		
	}];
}

- (BOOL)makePlayerItem
{
	isLocalFile_ = [self.sampleURL isFileURL];
	
	if (isLocalFile_) {
		self.playerItem = [AVPlayerItem playerItemWithAsset:urlAsset_];
	} else {
		self.playerItem = [AVPlayerItem playerItemWithURL:self.sampleURL];
	}
	
	[self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
	
	return (self.playerItem != nil);
}

- (void)initAssetWithURL
{
	self.playerItem = [AVPlayerItem playerItemWithURL:self.sampleURL];
	
	if (self.playerItem == nil) {
		return;
	}

	
}

- (BOOL)initPlayer
{
	if (self.playerItem == nil) {
		return NO;
	}
	avPlayer_ = [AVPlayer playerWithPlayerItem:self.playerItem];
	
	return YES;
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

#pragma mark - Observer

- (BOOL)readyToPlay
{
	BOOL isReadyToPlay = NO;
	if ((avPlayer_.currentItem != nil) &&
		([avPlayer_.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
		isReadyToPlay = YES;
	}
	
	return isReadyToPlay;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
 
	if (context == &ItemStatusContext) {
		dispatch_async(dispatch_get_main_queue(),
					   ^{
						   if ([self.delegate respondsToSelector:@selector(readyToPlay:)]) {
							   BOOL isReadyToPlay = [self readyToPlay];
							   [self.delegate readyToPlay:isReadyToPlay];
						   }
					   });
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object
						   change:change context:context];
}

@end
