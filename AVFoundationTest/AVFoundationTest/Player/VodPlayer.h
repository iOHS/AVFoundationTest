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
@property (nonatomic, weak) NSURL *sampleURL;

- (AVPlayer *)player;
- (void)loadPlayer:(void (^)(BOOL isLoadPlayer))result;
- (void)play;
- (void)pause;

@end

@protocol VodPlayerDelegate <NSObject>

- (void)readyToPlay:(BOOL)isReadyToPlay;

@end
