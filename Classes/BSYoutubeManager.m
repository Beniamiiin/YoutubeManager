//
//  BSYoutubeManager.m
//
//  Created by Beniamin Sarkisyan on 14.05.14.
//  Copyright (c) 2014 Beniamin Sarkisyan. All rights reserved.
//

#import "BSYoutubeManager.h"

#import "GTLYouTube.h"

static NSString *const kHasNotVideoErrorDomain = @"HasNotVideoErrorDomain";
enum
{
    OYYoutubeRequestNotVideoOnChannel = 1001
};

static int const kYoutubeVideoLimit = 25;

static GTLServiceYouTube *service;

typedef void(^ChannelQuery)(NSString *playlistID);
typedef void(^PlaylistItemsQuery)(NSString *videoIDs);
typedef void(^VideoQuery)(NSArray *videos);
typedef void(^QueryFailure)(NSError *error);

typedef void(^LoadVideoListSuccess)(NSArray *videoList);
typedef void(^LoadVideoListError)(NSString *title, NSString *message);

@interface BSYoutubeManager ()
{
    NSMutableArray *youtubeVideos;
    BOOL finishLoad;
}

@property (strong, nonatomic, readonly) ChannelQuery channelQuerySuccess;
@property (strong, nonatomic, readonly) PlaylistItemsQuery playlistItemsQuerySuccess;
@property (strong, nonatomic, readonly) VideoQuery videoQuerySuccess;
@property (strong, nonatomic, readonly) QueryFailure queryFailure;

@property (strong, nonatomic) LoadVideoListSuccess loadVideoListSuccess;
@property (strong, nonatomic) LoadVideoListError loadVideoListFailure;

@property (nonatomic, copy) NSString *nextPageToken;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *channelID;

- (void)executeChannelQueryWithSuccess:(void(^)(NSString *playlistID))success;

- (void)executePlaylistItemsQueryWithPlaylistID:(NSString *)playlistID
                                    withSuccess:(void(^)(NSString *videoIDs))success;

- (void)executeVideoListQueryWithVideoIDs:(NSString *)videoIDs
                              withSuccess:(void(^)(NSArray *videos))success;

@end

@implementation BSYoutubeManager

#pragma mark - Public methods -

#pragma mark Init methods
+ (BSYoutubeManager *)youtubeManagerWithApiKey:(NSString *)apiKey
                                     channelID:(NSString *)channelID
{
    return [[self alloc] initWithApiKey:apiKey channelID:channelID];
}

- (id)initWithApiKey:(NSString *)apiKey channelID:(NSString *)channelID
{
    if ( self = [super init] )
    {
        NSAssert(apiKey, @"apiKey can't be nil");
        NSAssert(channelID, @"channelID can't be nil");
        
        _channelID = channelID;
        
        service = [GTLServiceYouTube new];
        service.APIKey = apiKey;
        
        youtubeVideos = [@[] mutableCopy];

        finishLoad = NO;
    }
    
    return self;
}

#pragma mark Load methods
- (void)loadVideoListWithSuccess:(void(^)(NSArray *videoList))success
                     withFailure:(void(^)(NSString *title, NSString *message))failure
{
    if ( finishLoad )
        return;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [youtubeVideos removeAllObjects];

    self.loadVideoListSuccess = success;
    self.loadVideoListFailure = failure;
    
    [self executeChannelQueryWithSuccess:self.channelQuerySuccess];
}

#pragma mark Clear methods
- (void)clearCache
{
    [youtubeVideos removeAllObjects];
    self.nextPageToken = nil;
    finishLoad = NO;
}

#pragma mark - Private methods -

#pragma mark Queries methods
- (void)executeChannelQueryWithSuccess:(void(^)(NSString *playlistID))success
{
    GTLQueryYouTube *channelQuery = [GTLQueryYouTube queryForChannelsListWithPart:@"contentDetails"];
    channelQuery.identifier = _channelID;
    
    __weak typeof(self) weakSelf = self;
    [service executeQuery:channelQuery completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeChannelListResponse *channelList, NSError *error) {
        typeof(self) strongSelf = weakSelf;
        
        if ( error )
        {
            strongSelf.queryFailure(error);
            return;
        }
        
        if ( !channelList.items.count )
        {
            strongSelf.queryFailure(nil);
            return;
        }
        
        GTLYouTubeChannel *channel = [channelList.items firstObject];
        NSString *playlistID = channel.contentDetails.relatedPlaylists.uploads;
        
        if ( !playlistID.length )
        {
            strongSelf.queryFailure(nil);
            return;
        }
        
        if ( success )
            success(playlistID);
    }];
}

- (void)executePlaylistItemsQueryWithPlaylistID:(NSString *)playlistID
                                    withSuccess:(void(^)(NSString *videoIDs))success
{
    GTLQueryYouTube *playlistItemsQuery = [GTLQueryYouTube queryForPlaylistItemsListWithPart:@"snippet, contentDetails"];
    playlistItemsQuery.playlistId = playlistID;
    playlistItemsQuery.maxResults = kYoutubeVideoLimit;
    
    if ( self.nextPageToken )
        playlistItemsQuery.pageToken = [self.nextPageToken copy];
    
    __weak typeof(self) weakSelf = self;
    [service executeQuery:playlistItemsQuery completionHandler:^(GTLServiceTicket *ticket, GTLYouTubePlaylistItemListResponse *playlistItemList, NSError *error) {
        typeof(self) strongSelf = weakSelf;
        
        if ( error )
        {
            strongSelf.queryFailure(error);
            return;
        }
        
        if ( !playlistItemList.items.count )
        {
            strongSelf.queryFailure(nil);
            return;
        }
        
        finishLoad = ( !playlistItemList.nextPageToken && playlistItemList.prevPageToken );
        
        strongSelf.nextPageToken = playlistItemList.nextPageToken;
        
        NSMutableString *videoIDs = [@"" mutableCopy];
        
        NSArray *playlistItems = playlistItemList.items;
        
        for (GTLYouTubePlaylistItem *playlistItem in playlistItems)
        {
            GTLYouTubePlaylistItemSnippet *snippet = playlistItem.snippet;
            GTLYouTubePlaylistItemContentDetails *contentDetails = playlistItem.contentDetails;
            
            [videoIDs appendFormat:@"%@, ", contentDetails.videoId];
            
            BSYoutubeVideo *video = [BSYoutubeVideo new];
            video.uid = contentDetails.videoId;
            video.thumbnail = snippet.thumbnails.standard.url;
            video.title = snippet.title;
            video.info = snippet.descriptionProperty;
            video.publishDate = snippet.publishedAt.date;
            
            [youtubeVideos addObject:video];
        }
        
        if ( !youtubeVideos.count )
        {
            NSError *error = [self createHasNotVideoOnChannelError];
            strongSelf.queryFailure(error);
            
            return;
        }
        
        if ( success )
            success(videoIDs);
    }];
}

- (void)executeVideoListQueryWithVideoIDs:(NSString *)videoIDs
                              withSuccess:(void(^)(NSArray *videos))success
{
    GTLQueryYouTube *videosQuery = [GTLQueryYouTube queryForVideosListWithPart:@"statistics, player, contentDetails"];
    videosQuery.identifier = videoIDs;
    
    __weak typeof(self) weakSelf = self;
    [service executeQuery:videosQuery completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeVideoListResponse *videoList, NSError *error) {
        typeof(self) strongSelf = weakSelf;
        
        if ( error )
        {
            strongSelf.queryFailure(error);
            return;
        }
        
        if ( !videoList.items.count )
        {
            strongSelf.queryFailure(nil);
            return;
        }
        
        NSArray *videoListItems = videoList.items;
        
        for (GTLYouTubeVideo *video in videoListItems)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.uid == %@", video.identifier];
            
            NSArray *filtredArray = [youtubeVideos filteredArrayUsingPredicate:predicate];
            
            if ( !filtredArray.count )
                continue;
            
            BSYoutubeVideo *_video = [filtredArray firstObject];
            _video.dislikeCount = video.statistics.dislikeCount;
            _video.favoriteCount = video.statistics.favoriteCount;
            _video.likeCount = video.statistics.likeCount;
            _video.viewCount = video.statistics.viewCount;
            _video.duration = video.contentDetails.duration;
            _video.embedHtml = video.player.embedHtml;
        }
        
        if ( success )
            success(youtubeVideos);
    }];
}

#pragma mark Queries blocks
- (ChannelQuery)channelQuerySuccess
{
    __weak typeof(self) weakSelf = self;
    ChannelQuery block = ^(NSString *playlistID)
    {
        typeof(self) strongSelf = weakSelf;
        
        [strongSelf executePlaylistItemsQueryWithPlaylistID:playlistID
                                          withSuccess:strongSelf.playlistItemsQuerySuccess];
    };
    
    return block;
}

- (PlaylistItemsQuery)playlistItemsQuerySuccess
{
    __weak typeof(self) weakSelf = self;
    PlaylistItemsQuery block = ^(NSString *videoIDs)
    {
        typeof(self) strongSelf = weakSelf;
        
        [strongSelf executeVideoListQueryWithVideoIDs:videoIDs
                                    withSuccess:strongSelf.videoQuerySuccess];
    };
    
    return block;
}

- (VideoQuery)videoQuerySuccess
{
    __weak typeof(self) weakSelf = self;
    VideoQuery block = ^(NSArray *videos)
    {
        typeof(self) strongSelf = weakSelf;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if ( strongSelf.loadVideoListSuccess )
            strongSelf.loadVideoListSuccess(videos);
    };
    
    return block;
}

- (QueryFailure)queryFailure
{
    __weak typeof(self) weakSelf = self;
    QueryFailure block = ^(NSError *error)
    {
        typeof(self) strongSelf = weakSelf;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        NSString *alertTitle = NSLocalizedString(@"Attention", nil);
        NSString *alertMessage = NSLocalizedString(@"Something went wrong, please try again.", nil);
        
        if ( error.code == NSURLErrorNotConnectedToInternet )
        {
            alertMessage = NSLocalizedString(@"Internet problem", nil);
        }
        else if ( error.code == OYYoutubeRequestNotVideoOnChannel )
        {
            alertMessage = NSLocalizedString(error.localizedFailureReason, nil);
        }
        
        if ( strongSelf.loadVideoListFailure )
            strongSelf.loadVideoListFailure(alertTitle, alertMessage);
    };
    
    return block;
}

#pragma mark Helpers
- (NSError *)createHasNotVideoOnChannelError
{
    NSString *reason = NSLocalizedString(@"Not video on the channel", nil);
    NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey:reason};
    
    NSError *error = [NSError errorWithDomain:kHasNotVideoErrorDomain
                                         code:OYYoutubeRequestNotVideoOnChannel
                                     userInfo:userInfo];
    
    return error;
}

@end
