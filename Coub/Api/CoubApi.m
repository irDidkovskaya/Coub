//
//  CoubApi.m
//  
//
//  Created by Irina Didkovskaya on 1/28/14.
//
//

#import "CoubApi.h"
#import <AFNetworking.h>

#define EXPLORE_LINK @"http://coub.com/api/v1/timeline/explore"
#define HOT_LINK @"http://coub.com/api/v1/timeline/explore/hot"
#define RANDOM_LINK @"http://coub.com/api/v1/timeline/explore/random"

@implementation CoubApi

+ (instancetype)sharedCoubApi
{
    static CoubApi *sharedObject_ = nil;
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        sharedObject_ = [[self alloc] init];
    });
    return sharedObject_;
}



- (void)getItemsListFromLink:(NSString *)link loadPage:(int)page
           completionHandler:(void (^)(id data))completionHandler
                     failure:(void(^)(NSString *description))failure
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{kPageKey:@(page)};
    [manager GET:link parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        completionHandler(responseObject[kCoubsKey]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure([error localizedDescription]);
        NSLog(@"Error: %@", error);
    }];
    
}


- (void)getMP3DataFromLink:(NSString *)link
           completionHandler:(void (^)(id data))completionHandler

{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        NSData *data0 = [NSData dataWithContentsOfURL:[NSURL URLWithString:link]];
        
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            completionHandler(data0);
        });
    });
}



- (void)getItemListType:(enum ContentType)contentType pageNumber:(int)page
      conpletionHandler:(void (^)(id data))completionHandler
                failure:(void (^)(NSString *description))failure
{
    
    [self getItemsListFromLink:[self urlLinkForContentType:contentType] loadPage:page completionHandler:^(id data) {
        
        NSMutableArray *ma = [NSMutableArray array];
        for (NSDictionary *dict in data) {
            
            NSLog(@"dict = %@", dict);
            
            NSString *firstFrameVersions = dict[kTimelinePicture];
            NSString *title = dict[kTitleKey];
            NSString *iPhoneUrl = dict[kFileVersionsKey][kIphoneKey][kUrlKey];
            NSNumber *hasSound = [NSNumber numberWithBool:[dict[kHasSoundKey] boolValue]];
            NSString *sound = dict[kFileVersionsKey][kMobileKey][kAudioUrlKey];
            
            NSDictionary *colectedDict = @{kTitleKey:title, kIphoneUrl:iPhoneUrl, kFirstFrameVersionsKey: firstFrameVersions, kHasSoundKey: hasSound, kSoundURLKey:sound};
            
            [ma addObject:colectedDict];
        }
        completionHandler(ma);
    } failure:^(NSString *description) {
        failure(description);
    }];
     
}

- (NSString *)urlLinkForContentType:(enum ContentType)contentType
{
    NSString *urlString = nil;
    
    switch (contentType) {
        case ContentTypeExplore:
            urlString = EXPLORE_LINK;
            break;
        case ContentTypeHot:
            urlString = HOT_LINK;
            break;
        case ContentTypeRandom:
            urlString = RANDOM_LINK;
            break;
            
        default:
            break;
    }
    
    return urlString;
}



@end
