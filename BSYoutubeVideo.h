//
//  BSYoutubeVideo.h
//
//  Created by Beniamin Sarkisyan on 15.05.14.
//  Copyright (c) 2014 Beniamin Sarkisyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BSYoutubeVideo : NSObject

/**
 *  An <iframe> tag that embeds a player that will play the video.
 */
@property (nonatomic) NSString *embedHtml;

/**
 *  Video id
 */
@property (nonatomic) NSString *uid;

/**
 *  Video standart thumbnails
 */
@property (nonatomic) NSString *thumbnail;

/**
 *  Video title
 */
@property (nonatomic) NSString *title;

/**
 *  Video description
 */
@property (nonatomic) NSString *info;

/**
 *  Video published date
 */
@property (nonatomic) NSDate *publishDate;

/**
 *  The number of users who have indicated that they
 *  disliked the video by giving it a negative rating.
 */

@property (nonatomic) NSNumber *dislikeCount;

/**
 *  The number of users who currently have the video
 *  marked as a favorite video.
 */
@property (nonatomic) NSNumber *favoriteCount;

/**
 *  The number of users who have indicated that they
 *  liked the video by giving it a positive rating.
 */
@property (nonatomic) NSNumber *likeCount;

/**
 *  The number of times the video has been viewed.
 */
@property (nonatomic) NSNumber *viewCount;

/**
 *  The length of the video. The tag value is an ISO 8601 duration in the format
 *  PT#M#S, in which the letters PT indicate that the value specifies a period of
 *  time, and the letters M and S refer to length in minutes and seconds,
 *  respectively. The # characters preceding the M and S letters are both
 *  integers that specify the number of minutes (or seconds) of the video. For
 *  example, a value of PT15M51S indicates that the video is 15 minutes and 51
 *  seconds long.
 */
@property (nonatomic) NSString *duration;

@end
