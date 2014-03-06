//
//  FjSlider.h
//  forkjoy
//
//  Created by Adrian Corscadden on 12-07-05.
//  Copyright (c) 2012 Magic Pixel Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATCSlider : UIViewController <UIScrollViewDelegate>{
    
    UIScrollView        *_scrollView;
    NSMutableArray      *_titles;
    NSMutableArray      *_views;
    NSMutableArray      *_labels;
    
    UIScrollView        *_contentView;
    UIView              *_viewForTapping;
    
    BOOL                pageHasChanged;
    BOOL                initialViewSet;
    
}

@property (strong, nonatomic) NSMutableArray    *titles;
@property (strong, nonatomic) NSMutableArray    *views;
@property (strong, nonatomic) NSNumber          *initialViewIndex;

-(id)initWithTitles:(NSMutableArray*)titles andViews:(NSMutableArray*)views;

-(NSInteger)getPage;
-(void)refreshSlider;
-(void)tapRight;
-(void)tapLeft;
-(void)removeSubviews;

@end
