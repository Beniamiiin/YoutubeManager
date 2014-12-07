//
//  BSYoutubeManager.h
//
//  Created by Beniamin Sarkisyan on 14.05.14.
//  Copyright (c) 2014 Beniamin Sarkisyan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BSYoutubeVideo.h"

///-----------------------------------------------------------
/// class BSYoutubeManager Description
///-----------------------------------------------------------
@interface BSYoutubeManager : NSObject

/**
 *  Init method for class
 *
 *  @param apiKey - application api key, which created on https://console.developers.google.com/project
 *  @param channelID - chanel id
 *
 *  @return self
 */
+ (BSYoutubeManager *)youtubeManagerWithApiKey:(NSString *)apiKey channelID:(NSString *)channelID;

/**
 *  Init method for class
 *
 *  @param apiKey - application api key, which created on https://console.developers.google.com/project
 *  @param channelID - chanel id
 *
 *  @return self
 */
- (id)initWithApiKey:(NSString *)apiKey channelID:(NSString *)channelID;

/**
 *  Load vide from youtube channel
 *
 *  @param success - block call when response success
 *  @param failure - block call when response failure
 */
- (void)loadVideoListWithSuccess:(void(^)(NSArray *videoList))success
                     withFailure:(void(^)(NSString *title, NSString *message))failure;

/**
 *  Clear temp properties
 */
- (void)clearCache;

@end