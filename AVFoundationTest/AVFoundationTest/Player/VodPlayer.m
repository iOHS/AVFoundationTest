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

// Sample URL
#define VOD_SAMPLE @"http://www.ithinknext.com/mydata/board/files/F201308021823010.mp4"
// #define VOD_SAMPLE  @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"

// Define
#define KEY_TRACKS				@"tracks"
#define KEY_RATE				@"rate"
#define KEY_STATUS				@"status"
#define KEY_LOADEDTIMERANGES	@"loadedTimeRanges"
#define KEY_PLAYABLE			@"playable"
#define KEY_HASPROTECTEDCONTENT @"hasProtectedContent"

@interface VodPlayer ()

@property (nonatomic, assign) VodPlayStatus playStatus;

@end

@implementation VodPlayer {
	
	BOOL isLocalFile_;
	
	BOOL isInitPlayer_;
	
	AVPlayer *avPlayer_;
	AVAsset *asset_;
	AVPlayerItem *playerItem_;
	
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

#pragma mark - Public function

- (AVPlayer *)player
{
	return avPlayer_;
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

- (void)seekToTime:(Float64)seconds completed:(void (^)(BOOL completed))completed
{
	if (avPlayer_ != nil) {
		
		CGFloat seekSeconds = roundf(seconds);
		CMTime time = CMTimeMakeWithSeconds(seekSeconds, 1);
		[avPlayer_ seekToTime:time
			completionHandler:^(BOOL finished)
		 {
			 dispatch_async(dispatch_get_main_queue(), ^{
				 completed(finished);
			 });
		 }];
	}
}

- (void)setPlayStatus:(VodPlayStatus)playStatus
{
	_playStatus = playStatus;
	
	if ([self.delegate respondsToSelector:@selector(changedPlayStatus:)]) {
		[self.delegate changedPlayStatus:playStatus];
	}
}

- (BOOL)isVodPlaying
{
	return (avPlayer_ != nil && avPlayer_.rate > 0.0);
}

- (Float64)duration
{
	if (avPlayer_ != nil) {
		return CMTimeGetSeconds(avPlayer_.currentItem.duration);
	}
	
	return 0.0f;
}

#pragma mark - Private function

- (void)initAsset:(void (^)(BOOL isLoaded))result
{
	// urlAsset_ = [[AVURLAsset alloc] initWithURL:self.sampleURL options:nil];
	asset_ = [AVAsset assetWithURL:self.sampleURL];
	NSArray *keys = @[KEY_TRACKS];
	[asset_ loadValuesAsynchronouslyForKeys:keys completionHandler:^{
		
		NSError *error = nil;
		AVKeyValueStatus trackStatus = [asset_ statusOfValueForKey:KEY_TRACKS
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
		
		NSArray *assetKeys = @[KEY_PLAYABLE, KEY_HASPROTECTEDCONTENT];
		
		playerItem_ = [AVPlayerItem playerItemWithAsset:asset_ automaticallyLoadedAssetKeys:assetKeys];
		
		__block BOOL isCheckLoad = YES;
		
		[asset_ loadValuesAsynchronouslyForKeys:assetKeys completionHandler:^(void) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				
				if (asset_.isPlayable == NO) {
					
					isCheckLoad = NO;
					[self errorVodPlayer:VodErrorType_CannotPlay];
					
				} else if (asset_.hasProtectedContent) {
					
					isCheckLoad = NO;
					[self errorVodPlayer:VodErrorType_ProtectedContent];
				}
			});
		}];
		
		if (isCheckLoad == NO) {
			return NO;
		}
		
	} else {
		
		if (isLocalFile_) {
			playerItem_ = [AVPlayerItem playerItemWithAsset:asset_];
		} else {
			playerItem_ = [AVPlayerItem playerItemWithURL:self.sampleURL];
		}
	}
	
	if (playerItem_ == nil) {
		[self errorVodPlayer:VodErrorType_EmptyPlayerItem];
		return NO;
	}
	
	// Register as an observer of the player item's status property
	NSKeyValueObservingOptions options = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
	[playerItem_ addObserver:self
				  forKeyPath:KEY_STATUS
					 options:options
					 context:&PlayerItemContext];
	
	[playerItem_ addObserver:self
				  forKeyPath:KEY_LOADEDTIMERANGES
					 options:NSKeyValueObservingOptionNew
					 context:&PlayerItemContext];
	
	// Associate the player item with the player
	avPlayer_ = [AVPlayer playerWithPlayerItem:playerItem_];
	avPlayer_.actionAtItemEnd = AVPlayerActionAtItemEndPause;
	
	if (avPlayer_ == nil) {
		[self errorVodPlayer:VodErrorType_InitPlayerFail];
		return NO;
	}
	
	if (isInitPlayer_ == NO) {
		
		isInitPlayer_ = YES;
		
		[avPlayer_ addObserver:self forKeyPath:KEY_RATE options:NSKeyValueObservingOptionNew context:&PlayerItemContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playerItemDidReachEnd:)
													 name:AVPlayerItemDidPlayToEndTimeNotification
												   object:[avPlayer_ currentItem]];
		
		__block VodPlayer *vodPlayerObject = self;
		CMTime interval = CMTimeMakeWithSeconds(1.0, NSEC_PER_SEC); // 1 second
		playTimeObserver_ = [avPlayer_ addPeriodicTimeObserverForInterval:interval
																	queue:dispatch_get_main_queue()
															   usingBlock:^(CMTime time) {
																   
																   if ([vodPlayerObject.delegate respondsToSelector:@selector(updatePlayTime:)]) {
																	   [vodPlayerObject.delegate updatePlayTime:CMTimeGetSeconds(time)];
																   }
															   }];
	}
	
	
	return YES;
}

- (void)resetPlayer
{
	[self pause];
}

- (void)closePlayer
{
	[avPlayer_ removeTimeObserver:playTimeObserver_];
}

#pragma mark - VodPlayerDelegate

- (BOOL)readyToPlay
{
	return ((avPlayer_.currentItem != nil) && ([avPlayer_.currentItem status] == AVPlayerItemStatusReadyToPlay));
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	[self resetPlayer];
	
	if ([self.delegate respondsToSelector:@selector(didPlayReachEnd)]) {
		[self.delegate didPlayReachEnd];
	}
}

- (void)errorVodPlayer:(VodErrorType)type
{
	if ([self.delegate respondsToSelector:@selector(failVodPlayerWithErrorType:)]) {
		[self.delegate failVodPlayerWithErrorType:type];
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
	
	if ([keyPath isEqualToString:KEY_STATUS]) {
		
		NSNumber *statusNumber = change[NSKeyValueChangeNewKey];
		
		if ([statusNumber isKindOfClass:[NSNumber class]]) {
			
			/*
			 * <AVPlayerItemStatus>
			 * - AVPlayerItemStatusUnknown,
			 * - AVPlayerItemStatusReadyToPlay,
			 * - AVPlayerItemStatusFailed
			 */
			
			AVPlayerItemStatus status = [statusNumber integerValue];
			dispatch_async(dispatch_get_main_queue(),^{
				if ([self.delegate respondsToSelector:@selector(readyToPlay:duration:)]) {
					[self.delegate readyToPlay:(status == AVPlayerItemStatusReadyToPlay) duration:[self duration]];
				}
			});
		}
		
	} else if ([keyPath isEqualToString:KEY_RATE]) {
		
		NSNumber *statusNumber = change[NSKeyValueChangeNewKey];
		
		if ([statusNumber isKindOfClass:[NSNumber class]]) {
			float rate = [statusNumber floatValue];
			dispatch_async(dispatch_get_main_queue(),^{
				
				if ([self.delegate respondsToSelector:@selector(changedPlayStatus:)]) {
					
					VodPlayStatus status = VodPlayStatus_Stop;
					if (rate == 1.0f) {
						status = VodPlayStatus_Playing;
					}
					
					[self.delegate changedPlayStatus:status];
				}
			});
		}
		
	} else if ([keyPath isEqualToString:KEY_LOADEDTIMERANGES]) {
		
		NSTimeInterval timeInterval = [self playableDuration];
		// NSLog(@"Time Interval:%f",timeInterval);
		CMTime duration = avPlayer_.currentItem.duration;
		CGFloat totalDuration = CMTimeGetSeconds(duration);
		CGFloat bufferRate = timeInterval / totalDuration;
		
		if ([self.delegate respondsToSelector:@selector(updateBufferWithRate:)]) {
			[self.delegate updateBufferWithRate:bufferRate];
		}
	}
}

- (NSTimeInterval)playableDuration
{
	if (avPlayer_ == nil) {
		return 0.0f;
	}
	
	if (avPlayer_.currentItem != nil && avPlayer_.currentItem.status == AVPlayerStatusReadyToPlay) {
		
		NSArray *loadedTimeRanges = [avPlayer_.currentItem loadedTimeRanges];
		CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
		CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
		CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
		NSTimeInterval playableDuration = startSeconds + durationSeconds;
		return playableDuration;
	}
	
	return 0.0f;
	
}

@end
