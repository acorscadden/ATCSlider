//
//  ATCSlider.m
//
//  Created by Adrian Corscadden on 12-07-05.
//

#import "ATCSlider.h"

#import <QuartzCore/QuartzCore.h>
#include <libkern/OSMemoryNotification.h>

#define TAB_WIDTH       106
#define TAB_HEIGHT      44
#define SCREEN_WIDTH    320

#define kBackgroundColour kLightBlueColour
#define kSelectedBoxColour kDarkBlueColour

@interface ATCSlider ()

@property (assign) BOOL isStartOfScroll;

@end

@implementation ATCSlider

-(id)initWithTitles:(NSMutableArray*)titles andViews:(NSMutableArray*)views{
    self = [super init];
    
    if (self) {
        _titles = titles;
        _views = views;
    }
    
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    initialViewSet = NO;
    self.edgesForExtendedLayout = UIRectEdgeBottom;
    
    _labels = [[NSMutableArray alloc] init];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-TAB_WIDTH)/2, 0, TAB_WIDTH, TAB_HEIGHT)];
    _scrollView.contentSize = CGSizeMake([_titles count]*TAB_WIDTH, TAB_HEIGHT);
    _scrollView.pagingEnabled = YES;
    _scrollView.clipsToBounds = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
    _scrollView.userInteractionEnabled = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, TAB_HEIGHT)];
    redView.backgroundColor = UIColorFromRGB(kNavBarBackground);
    [self.view addSubview:redView];
    
    UIView *highlight = [[UIView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-TAB_WIDTH)/2, 0, TAB_WIDTH, TAB_HEIGHT)];
    highlight.backgroundColor = self.view.tintColor;
    highlight.userInteractionEnabled = NO;
    
    [self.view addSubview:highlight];

    [self setUpContentView];
    [self.view addSubview:_scrollView];
    
    UITapGestureRecognizer *tr =                [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    _viewForTapping =                           [[UIView alloc] initWithFrame:CGRectMake(0, 0, kUIiPhoneWidth*10, 44)];
    _viewForTapping.userInteractionEnabled =    YES;
    [_viewForTapping                            addGestureRecognizer:tr];
    [_contentView                               addSubview:_viewForTapping];
    
    pageHasChanged = NO;
    [self refreshSlider];
    
    UIView *topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 1)];
    topBorder.backgroundColor = self.view.tintColor;
    [self.view addSubview:topBorder];
    
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, TAB_HEIGHT-1, SCREEN_WIDTH, 1)];
    bottomBorder.backgroundColor = self.view.tintColor;
    [self.view addSubview:bottomBorder];
    
    self.isStartOfScroll = YES;
    
}

- (void)viewDidAppear:(BOOL)animated{
    [self.navigationController.navigationBar setBackgroundImage:[DCHelpers imageForColor:UIColorFromRGB(kNavBarBackground)] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:nil];
}

- (void)setUpContentView{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat height = screenSize.height - (kUINavBarHeight+kUIIPhoneTabBarHeight+20);
    
    _contentView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,
                                                                  0,
                                                                  kUIiPhoneWidth,
                                                                  height)];
    _contentView.delegate = self;
    _contentView.scrollsToTop = NO;
    _contentView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_contentView];
}

- (void)setInitialView{
    _contentView.contentOffset = CGPointMake([_initialViewIndex integerValue]*kUIiPhoneWidth, 0);
}

-(void)removeSubviews{
    //set sliders properties for children//
    for (id viewController in _views) {
        if ([viewController isKindOfClass:[DCSliderSubTableViewController class]] || [viewController isKindOfClass:[DCSliderSubViewController class]] || [viewController isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = viewController;
            [vc.view removeFromSuperview];
        }
    }
}

- (void)addDelayedViewNotIncludingIndex:(NSNumber*)index{
    int i = 0;
    for (UIViewController *vc in _views) {
        
        if (i != [index integerValue]) {
            vc.view.frame = CGRectMake(kUIiPhoneWidth*i, kUINavBarHeight, kUIiPhoneWidth, _contentView.frame.size.height-kUINavBarHeight);
            
            if ([vc respondsToSelector:@selector(tableView)]) {
                UITableView *tableView = (UITableView*)[vc performSelector:@selector(tableView)];
                tableView.frame = vc.view.bounds;
            }
            
            [_contentView addSubview:vc.view];
        }
        i++;
    }
}

-(void)refreshSlider{
    
    for (id viewController in _views) {
        if ([viewController respondsToSelector:@selector(setSlider:)]) {
            [viewController setSlider:self];
        }
    }
    
    if (self.initialViewIndex) {
        
        //add initial view
        int initialIndex = [self.initialViewIndex intValue];
        UIViewController *initialView = _views[initialIndex];
        if ([initialView.view isKindOfClass:[UIScrollView class]]){
            [((UIScrollView *)initialView.view) setScrollsToTop:YES];
        }
        initialView.view.frame = CGRectMake(kUIiPhoneWidth*initialIndex, kUINavBarHeight, kUIiPhoneWidth, _contentView.frame.size.height - kUINavBarHeight);
        
        if ([initialView respondsToSelector:@selector(tableView)]) {
            UITableView *tableView = (UITableView*)[initialView performSelector:@selector(tableView)];
            
            tableView.frame = initialView.view.bounds;
        }
        
        [_contentView addSubview:initialView.view];
        
        //FIXME
        //add rest after delay
        [self performSelector:@selector(addDelayedViewNotIncludingIndex:) withObject:@(initialIndex)];
        
    } else {
        int i = 0;
        for (UIViewController *vc in _views) {
            if ([vc.view isKindOfClass:[UIScrollView class]]){
                [((UIScrollView *)vc.view) setScrollsToTop:NO];
            }
            vc.view.frame = CGRectMake(kUIiPhoneWidth*i, kUINavBarHeight, kUIiPhoneWidth, _contentView.frame.size.height - kUINavBarHeight);
            
            if ([vc respondsToSelector:@selector(tableView)]) {
                UITableView *tableView = (UITableView*)[vc performSelector:@selector(tableView)];
                
                tableView.frame = vc.view.bounds;
            }
            
            i++;
            [_contentView addSubview:vc.view];
        }
    }
    
    _contentView.contentSize = CGSizeMake([_views count]*kUIiPhoneWidth, _contentView.frame.size.height);
    _contentView.pagingEnabled = YES;
    
    for (UIView *view in _scrollView.subviews) {
        [view removeFromSuperview];
    }

    [_labels removeAllObjects];
    _scrollView.contentSize = CGSizeMake([_titles count]*TAB_WIDTH, TAB_HEIGHT);
    for (int i = 0; i < [_titles count]; i++) {
        
        //add loading indicator for menu view
        if ([[_titles objectAtIndex:i] isEqualToString:@"loading"]) {
            UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(i*TAB_WIDTH, 0, TAB_WIDTH, TAB_HEIGHT)];
            [loading startAnimating];
            [_scrollView addSubview:loading];
            [_titles removeObjectAtIndex:i];
        } else {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(i*TAB_WIDTH, 0, TAB_WIDTH, TAB_HEIGHT)];
            label.text = [_titles objectAtIndex:i];
            label.textAlignment = NSTextAlignmentCenter;
            label.backgroundColor = [UIColor clearColor];
            label.numberOfLines = 0;
            label.textColor = [UIColor blackColor];
            [_scrollView addSubview:label];
            [_labels addObject:label];
            
        }
    }
    
    if (_initialViewIndex && !initialViewSet) {
        initialViewSet = YES;
        [self setInitialView];
    }
    
    [self setCurrentViews];
    
}

-(void)tap:(UIGestureRecognizer*)sender{

    CGPoint location = [sender locationInView:self.view];
    if (location.y < 44.0) {
        if (location.x < 98) {
            pageHasChanged = YES;
            [self tapLeft];
        } else if (location.x > 222){
            pageHasChanged = YES;
            [self tapRight];
        }
    }
}

-(void)tapLeft{
    int page = (int)(_contentView.contentOffset.x/kUIiPhoneWidth);
    if (page > 0) {
        page--;
        [_contentView setContentOffset:CGPointMake(page*kUIiPhoneWidth, 0) animated:YES];
    }
}

-(void)tapRight{
    int page = (int)(_contentView.contentOffset.x/kUIiPhoneWidth);
    if (page < [_views count] - 1) {
        page++;
        [_contentView setContentOffset:CGPointMake(page*kUIiPhoneWidth, 0) animated:YES];
    }
}

-(void)setCurrentViews{
    
    int page = (int)(_scrollView.contentOffset.x/TAB_WIDTH);
    
    for (UILabel *label in _labels) {
        [label setTextColor:self.view.tintColor];
    }
    
    [(UILabel*)[_labels objectAtIndex:page] setTextColor:[UIColor whiteColor]];
    int i = 0;
    
    for (UIViewController *vc in _views) {
        if ([vc respondsToSelector:@selector(setTableViewScrollsToTop:)]) {
            if (i==page) {
                [vc performSelector:@selector(setTableViewScrollsToTop:) withObject:@(YES)];
            } else {
                [vc performSelector:@selector(setTableViewScrollsToTop:) withObject:@(NO)];
            }
        }
        i++;
    }
    self.isStartOfScroll = YES;
}

-(NSInteger)getPage{
    return (int)(_scrollView.contentOffset.x/TAB_WIDTH);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if ([scrollView isEqual:_contentView]) {
        CGFloat percent = _contentView.contentOffset.x/_contentView.frame.size.width;
        CGFloat x = percent*_scrollView.frame.size.width;
        _scrollView.contentOffset = CGPointMake(x, 0);
    }
    
    if (self.isStartOfScroll) {
        for (UILabel *label in _labels) {
            label.textColor = [UIColor blackColor];
        }
        
        self.isStartOfScroll = NO;
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [self setCurrentViews];
    self.isStartOfScroll = YES;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self setCurrentViews];
}

@end
