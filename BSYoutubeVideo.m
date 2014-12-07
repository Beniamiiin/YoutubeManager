//
//  BSYoutubeVideo.m
//
//  Created by Beniamin Sarkisyan on 15.05.14.
//  Copyright (c) 2014 Beniamin Sarkisyan. All rights reserved.
//

#import "BSYoutubeVideo.h"

@implementation BSYoutubeVideo

- (NSString *)description
{
    return [NSString stringWithFormat:@"{uid:%@, thumbnail:%@, title: %@, info: %@, date: %@, viewCount: %@}", _uid, _thumbnail, _title, _info, _publishDate, _viewCount];
}

@end
