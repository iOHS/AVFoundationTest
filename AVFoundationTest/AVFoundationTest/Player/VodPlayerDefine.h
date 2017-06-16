//
//  VodPlayerDefine.h
//  AVFoundationTest
//
//  Created by OHSEUNGWOOK on 2017. 6. 15..
//  Copyright © 2017년 OHSEUNGWOOK. All rights reserved.
//

#ifndef VodPlayerDefine_h
#define VodPlayerDefine_h

// VodPlayStatus
typedef NS_ENUM(NSInteger, VodPlayStatus) {
	VodPlayStatus_Playing,
	VodPlayStatus_Pause,
	VodPlayStatus_Stop,
};

// VodErrorType
typedef NS_ENUM(NSInteger, VodErrorType){
	VodErrorType_CannotPlay,
	VodErrorType_ProtectedContent,
	VodErrorType_EmptyPlayerItem,
	VodErrorType_InitPlayerFail
};

#endif /* VodPlayerDefine_h */
