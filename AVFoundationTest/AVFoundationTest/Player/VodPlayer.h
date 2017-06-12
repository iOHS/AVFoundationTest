//
//  VodPlayer.h
//  AVFoundationTest
//
//  Created by OHSEUNGWOOK on 2017. 6. 8..
//  Copyright © 2017년 OHSEUNGWOOK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol VodPlayerDelegate;

@interface VodPlayer : NSObject

@property (nonatomic, weak) id<VodPlayerDelegate> delegate;
@property (nonatomic, copy) NSURL *sampleURL;
@property (nonatomic, assign) BOOL ispreloadAssetProperty;

- (AVPlayer *)player;
- (void)loadPlayer:(void (^)(BOOL isLoadPlayer))result;
- (void)play;
- (void)pause;

@end

@protocol VodPlayerDelegate <NSObject>

- (void)readyToPlay:(BOOL)isReadyToPlay duration:(Float64)duration;
- (void)didPlayReachEnd;

- (void)updatePlayTime:(Float64)playTime;

@end
