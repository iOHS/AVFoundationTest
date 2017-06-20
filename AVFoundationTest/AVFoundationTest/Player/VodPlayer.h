//
//  VodPlayer.h
//  AVFoundationTest
//
//  Created by OHSEUNGWOOK on 2017. 6. 8..
//  Copyright © 2017년 OHSEUNGWOOK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VodPlayerDefine.h"

@protocol VodPlayerDelegate;

@interface VodPlayer : NSObject

@property (nonatomic, weak) id<VodPlayerDelegate> delegate;
@property (nonatomic, copy) NSURL *sampleURL;
@property (nonatomic, assign) BOOL ispreloadAssetProperty;

@property (nonatomic, assign, readonly) VodPlayStatus playStatus;

// Player Object
- (AVPlayer *)player;

// Player Control
- (void)loadPlayer:(void (^)(BOOL isLoadPlayer))result;
- (void)play;
- (void)pause;
- (void)seekToTime:(Float64)seconds completed:(void (^)(BOOL completed))completed;

// AVPlayer does not have a method named stop. You can pause or set rate to 0.0.
//- (void)stop;

// Player Status

- (Float64)duration;
- (BOOL)isVodPlaying;

@end

@protocol VodPlayerDelegate <NSObject>

- (void)readyToPlay:(BOOL)isReadyToPlay duration:(Float64)duration;
- (void)updateBufferWithRate:(CGFloat)bufferRate;
- (void)updatePlayTime:(Float64)playTime;
- (void)didPlayReachEnd;

- (void)changedPlayStatus:(VodPlayStatus)status;
- (void)failVodPlayerWithErrorType:(VodErrorType)errorType;

@end
