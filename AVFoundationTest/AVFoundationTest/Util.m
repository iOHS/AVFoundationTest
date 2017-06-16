//
//  Util.m
//  AVFoundationTest
//
//  Created by OHSEUNGWOOK on 2017. 6. 16..
//  Copyright © 2017년 OHSEUNGWOOK. All rights reserved.
//

#import "Util.h"

@implementation Util

+ (NSString *)timeFormatted:(NSInteger)totalSeconds
{
	
	NSInteger seconds = totalSeconds % 60;
	NSInteger minutes = (totalSeconds / 60) % 60;
	NSInteger hours = totalSeconds / 3600;
	
	return [NSString stringWithFormat:@"%02zd:%02zd:%02zd", hours, minutes, seconds];
}

@end
