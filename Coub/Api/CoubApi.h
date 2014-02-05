//
//  CoubApi.h
//  
//
//  Created by Irina Didkovskaya on 1/28/14.
//
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface CoubApi : NSObject

+ (instancetype)sharedCoubApi;
- (void)getItemListType:(enum ContentType)contentType pageNumber:(int)page
      conpletionHandler:(void (^)(id data))completionHandler
                failure:(void (^)(NSString *description))failure;


- (void)getMP3DataFromLink:(NSString *)link
         completionHandler:(void (^)(id data))completionHandler;
@end
