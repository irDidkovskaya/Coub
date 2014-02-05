//
//  ViewController.m
//  Coub
//
//  Created by Irina Didkovskaya on 1/28/14.
//  Copyright (c) 2014 Irina. All rights reserved.
//

#import "MainViewController.h"
#import "CoubTableCell.h"
#import <UIImageView+AFNetworking.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "SWRevealViewController.h"

@interface MainViewController () <UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate, SWRevealViewControllerDelegate>
{
    int page;
}
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *itemList;
@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayController;
@property (nonatomic, strong) UIActivityIndicatorView *mainSpiner;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation MainViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerDidChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];

    
    
    UIBarButtonItem *sidebarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self.revealViewController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = sidebarButton;
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    self.revealViewController.delegate = self;
    
    page = 0;
    
    self.mainSpiner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.mainSpiner.center = self.view.center;
    self.mainSpiner.hidesWhenStopped = YES;
    [self.mainSpiner startAnimating];
    self.tableView.hidden = YES;
    [self.view addSubview:self.mainSpiner];
    
    [self loadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"log = %@", NSStringFromCGRect(self.view.bounds));
    self.mainSpiner.center = self.view.center;
    
}

- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
    self.view.userInteractionEnabled = !self.view.userInteractionEnabled;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.itemList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    
    CoubTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[CoubTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.mediaName.text = self.itemList[indexPath.row][kTitleKey];
    [cell.imageMediaView setImageWithURL:[NSURL URLWithString:self.itemList[indexPath.row][kFirstFrameVersionsKey] ]placeholderImage:nil];
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.audioPlayer = nil;
    self.moviePlayController = nil;
    self.moviePlayController = [[MPMoviePlayerViewController alloc] init];
    self.moviePlayController.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    [self.moviePlayController.moviePlayer setContentURL:[NSURL URLWithString:self.itemList[indexPath.row][kIphoneUrl]]];
    [self.moviePlayController.moviePlayer prepareToPlay];
    self.moviePlayController.moviePlayer.shouldAutoplay = NO;
    self.moviePlayController.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    [self presentMoviePlayerViewControllerAnimated:self.moviePlayController];

    
    NSDictionary *dict = self.itemList[indexPath.row];
    BOOL hasSound = [dict[kHasSoundKey] boolValue];
    NSString *urlString = self.itemList[indexPath.row][kSoundURLKey];
    if (!hasSound && [urlString isKindOfClass:[NSString class]] && urlString.length)
    {
        [self playSound:self.itemList[indexPath.row][kSoundURLKey]];
    } else {
        [self.moviePlayController.moviePlayer play];
    }
    
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scroll {
    
    NSInteger currentOffset = scroll.contentOffset.y;
    NSInteger maximumOffset = scroll.contentSize.height - scroll.frame.size.height;
    
    if (maximumOffset - currentOffset <= 10.0) {
        if (!self.mainSpiner.isAnimating) {
            [self.mainSpiner startAnimating];
            [self loadData];
        }
    }
}

- (void)playSound:(NSString *)urlString
{
    [[CoubApi sharedCoubApi] getMP3DataFromLink:urlString completionHandler:^(id data) {
        self.audioPlayer = nil;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
        self.audioPlayer.numberOfLoops = 0;
        self.audioPlayer.delegate = self;
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
        [self.moviePlayController.moviePlayer play];

    }];
    
}

#pragma mark Notifications


- (void)moviePlayerDidChanged:(NSNotification*)notification
{
    if (self.audioPlayer)
    {
        if (self.moviePlayController.moviePlayer.playbackState == MPMoviePlaybackStatePaused) {
            [self.audioPlayer pause];
            [self.moviePlayController.moviePlayer pause];
        } else if (self.moviePlayController.moviePlayer.playbackState == MPMoviePlaybackStatePlaying)
        {
            [self.audioPlayer play];
            [self.moviePlayController.moviePlayer play];
        } else if (self.moviePlayController.moviePlayer.playbackState == MPMoviePlaybackStateStopped)
        {
            [self.audioPlayer stop];
            [self.moviePlayController.moviePlayer stop];
        }
    }
    NSLog(@"self.moviePlayController.moviePlayer.playbackState = %d", self.moviePlayController.moviePlayer.playbackState);
}

#pragma mark AVaudioPlayerDelegate
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"error = %@", [error description]);
    [self dismissMoviePlayerViewControllerAnimated];
    self.moviePlayController = nil;
    [self.audioPlayer stop];
    self.audioPlayer = nil;
}

#pragma mark LOAD DATA
- (void)loadData
{
    page++;
    [[CoubApi sharedCoubApi] getItemListType:self.contentType pageNumber:page conpletionHandler:^(id data) {
        
        
        NSMutableArray *arr = [NSMutableArray arrayWithArray:self.itemList];
        for (NSDictionary *dict in data) {
            [arr addObject:dict];
        }
        
        self.itemList = arr;
        [self.tableView reloadData];
        [self.mainSpiner stopAnimating];
        self.tableView.hidden = NO;
    } failure:^(NSString *description) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:description delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
        [alertView show];
        [self.mainSpiner stopAnimating];
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.mainSpiner.center = self.view.center;
}


@end
