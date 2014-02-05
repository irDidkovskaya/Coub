//
//  Constants.h
//  Coub
//
//  Created by Irina Didkovskaya on 1/30/14.
//  Copyright (c) 2014 Irina. All rights reserved.
//

#import <Foundation/Foundation.h>

enum ContentType {
    ContentTypeExplore = 0,
    ContentTypeHot = 1,
    ContentTypeRandom = 2
};


extern NSString *const kTitleKey;
extern NSString *const kFileVersionsKey;
extern NSString *const kIphoneKey;
extern NSString *const kUrlKey;
extern NSString *const kHasSoundKey;
extern NSString *const kMobileKey;
extern NSString *const kAudioUrlKey;

extern NSString *const kIphoneUrl;
extern NSString *const kFirstFrameVersionsKey;
extern NSString *const kSoundURLKey;
extern NSString *const kTimelinePicture;
extern NSString *const kPageKey;
extern NSString *const kCoubsKey;

@interface Constants : NSObject

@end
