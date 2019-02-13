//
//  JYGraphView.m
//  JYGraphViewController
//
//  Created by John Yorke on 23/08/2014.
//  Copyright (c) 2014 John Yorke. All rights reserved.
//

#import "JYGraphView.h"
#import "JYGraphPoint.h"

NSUInteger const kGapBetweenBackgroundVerticalBars = 4;
NSInteger const kPointLabelOffsetFromPointCenter = 20;
NSInteger const kBarLabelHeight = 20;
NSInteger const kPointLabelHeight = 20;

@interface JYGraphView ()

@property (nonatomic, strong) UIView *graphView;
@property (nonatomic, strong) UIView *verticalView;
@property (nonatomic, strong) UILabel *lowLabel;
@property (nonatomic, strong) UILabel *midLabel;
@property (nonatomic, strong) UILabel *highLabel;
@property (nonatomic, strong) UILabel *topLabel;

@end

#import "JYGraphView.h"

@implementation JYGraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    if ([self.graphData count] > 0 && newSuperview != nil) {
        [self plotGraphData];
    }
}

- (void)setDefaultValues
{
    // Set defaults values/options if none are set
    if (!_strokeColor) {
        _strokeColor = [UIColor colorWithRed:0.71f green: 1.0f blue: 0.196f alpha: 1.0f];
    }
    if (!_pointFillColor) {
        _pointFillColor = [UIColor colorWithRed: 0.219f green: 0.657f blue: 0 alpha: 1.0f];
    }
    if (!self.graphWidth) {
        self.graphWidth = self.frame.size.width * 2;
    }
    if (!self.backgroundViewColor) {
        self.backgroundViewColor = [UIColor blackColor];
    }
    if (!self.barColor) {
        self.barColor = [UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:1.0f];
    }
    if (!self.labelFont) {
        self.labelFont = [UIFont fontWithName:@"Futura-Medium" size:12];
    }
    if (!self.labelFontColor) {
        self.labelFontColor = [UIColor whiteColor];
    }
    if (!self.labelXFont) {
        self.labelXFont = self.labelFont;
    }
    if (!self.labelXFontColor) {
        self.labelXFontColor = self.labelFontColor;
    }
    if (!self.labelBackgroundColor) {
        self.labelBackgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
    }
    if (!self.strokeWidth) {
        self.strokeWidth = 2;
    }
    if (!self.yAxisWidth) {
        self.yAxisWidth = 15;
    }
}

#pragma mark - Graph plotting

- (void)plotGraphData
{
    if (_graphData == nil || _graphData.count == 0) {
        return;
    }
    self.userInteractionEnabled = YES;
    [self setDefaultValues];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.yAxisWidth, 0, self.frame.size.width - self.yAxisWidth, self.frame.size.height)];
    _scrollView.delegate = self;
    
    [self addSubview:_scrollView];
    self.graphView = [[UIView alloc] initWithFrame:_scrollView.frame];
    _scrollView.backgroundColor = self.backgroundViewColor;
    [_scrollView setContentSize:CGSizeMake(self.graphWidth - 20, _scrollView.frame.size.height)];
    [_scrollView addSubview:_graphView];
    
    NSInteger xCoordOffset = (self.graphWidth / [_graphData count]) - 10;
    [_graphView setFrame:CGRectMake(0 - xCoordOffset, 0, self.graphWidth, _scrollView.frame.size.height)];
    
    NSMutableArray *pointsCenterLocations = [[NSMutableArray alloc] init];
    
    NSArray *array = [_graphData sortedArrayUsingSelector:@selector(compare:)];
    float lowest = [[array objectAtIndex:0] floatValue];
    float highest = [[array objectAtIndex:[array count] - 1] floatValue];
    float range = highest - lowest;
    
    //    NSDictionary *graphRange = [self workOutRangeFromArray:_graphData];
    //    NSInteger range = [[graphRange objectForKey:@"range"] integerValue];
    //    NSInteger lowest = [[graphRange objectForKey:@"lowest"] integerValue];
    //    NSInteger highest = [[graphRange objectForKey:@"highest"] integerValue];
    
    // in case all numbers are zero or all the same value
    if (range == 0) {
        lowest = 0;
        if (highest == 0) {
            highest = 50; //arbitary number in case all numbers are 0
        }
        range = highest;
    }
    
    CGPoint lastPoint = CGPointMake(0, 0);
    
    NSInteger offsets = kPointLabelHeight + kPointLabelOffsetFromPointCenter;
    if (_hideLabels == NO && _graphDataLabels != nil) {
        offsets += kBarLabelHeight;
    }
    
    NSInteger offSetFromTop = 10;
    NSInteger offsetFromBottom = 10;
    float screenHeight = (_scrollView.frame.size.height - (offsets)) / (_scrollView.frame.size.height + offSetFromTop + offsetFromBottom);
    
    
    for (NSUInteger counter = 1; counter <= [_graphData count]; counter++) {
        NSInteger xCoord = (self.graphWidth / [_graphData count]) * counter;
        CGPoint point = CGPointMake(xCoord,
                                    _scrollView.frame.size.height - (([[_graphData objectAtIndex:counter - 1] integerValue] *
                                                                      ((_scrollView.frame.size.height * screenHeight) / range)) -
                                                                     (lowest * ((_scrollView.frame.size.height * screenHeight) / range ))+
                                                                     offsetFromBottom));
        
        [self createBackgroundVerticalBarWithXCoord:point withXAxisLabelIndex:counter-1];
        
        if (self.hideLabels == NO) {
            [self createPointLabelForPoint:point withLabelText:[NSString stringWithFormat:@"%@",[_graphData objectAtIndex:counter - 1]]];
        }
        
        if (self.useCurvedLine == NO) {
            // Check it's not the first item
            if (lastPoint.x != 0) {
                if (!self.hideLines) {
                    [self drawLineBetweenPoint:lastPoint andPoint:point withColour:_strokeColor];
                }
            }
        }
        
        NSValue *pointValue = [[NSValue alloc] init];
        pointValue = [NSValue valueWithCGPoint:point];
        [pointsCenterLocations addObject:pointValue];
        lastPoint = point;
    }
    
    if (self.useCurvedLine == YES && self.hideLines == NO) {
        [self drawCurvedLineBetweenPoints:pointsCenterLocations];
    }
    
    // Now draw all the points
    if (self.hidePoints == NO) {
        [self drawPointswithStrokeColour:_strokeColor
                                 andFill:_pointFillColor
                               fromArray:pointsCenterLocations];
    }
    
    if (_verticalView == nil) {
        _verticalView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.yAxisWidth, _scrollView.frame.size.height)];
        _verticalView.backgroundColor = _scrollView.backgroundColor;
        [self addSubview:_verticalView];
    }
    
    CGPoint lowPoint = CGPointMake((self.graphWidth / [_graphData count]),
                                   _scrollView.frame.size.height - ((lowest *
                                                                     ((_scrollView.frame.size.height * screenHeight) / range)) -
                                                                    (lowest * ((_scrollView.frame.size.height * screenHeight) / range ))+
                                                                    offsetFromBottom));
    if (_lowLabel == nil) {
        _lowLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, lowPoint.y - 5, self.yAxisWidth - 2, 8)];
        [_verticalView addSubview:_lowLabel];
    }
    _lowLabel.text = [NSString stringWithFormat:@"%ld", (long)lowest];
    _lowLabel.font = self.labelFont;
    _lowLabel.textColor = self.labelFontColor;
    _lowLabel.frame = CGRectMake(2, lowPoint.y - 5, self.yAxisWidth - 2, 8);
    _lowLabel.center = CGPointMake(_lowLabel.center.x, lowPoint.y);
    
    float multiplier = 1.25;
    CGPoint topPoint = CGPointMake((self.graphWidth / [_graphData count]),
                                    _scrollView.frame.size.height - ((highest * multiplier *
                                                                      ((_scrollView.frame.size.height * screenHeight) / range)) -
                                                                     (lowest * ((_scrollView.frame.size.height * screenHeight) / range ))+
                                                                     offsetFromBottom));
    
    CGFloat topOffset = _graphDataLabels.count > 0 ? kBarLabelHeight : 0;
    if (topPoint.y < topOffset) {
        multiplier = 1.1;
        topPoint = CGPointMake((self.graphWidth / [_graphData count]),
                                _scrollView.frame.size.height - ((highest * multiplier *
                                                                  ((_scrollView.frame.size.height * screenHeight) / range)) -
                                                                 (lowest * ((_scrollView.frame.size.height * screenHeight) / range ))+
                                                                 offsetFromBottom));
    }
    
    if (_topLabel == nil) {
        _topLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, topPoint.y - 5, self.yAxisWidth - 2, 8)];
        [_verticalView addSubview:_topLabel];
    }
    _topLabel.text = [NSString stringWithFormat:@"%ld", (long)(highest * multiplier)];
    _topLabel.font = _labelFont;
    _topLabel.textColor = _labelFontColor;
    _topLabel.frame = CGRectMake(2, topPoint.y - 5, self.yAxisWidth - 2, 8);
    _topLabel.center = CGPointMake(_topLabel.center.x, topPoint.y);
    
    CGPoint highPoint = CGPointMake((self.graphWidth / [_graphData count]),
                                    _scrollView.frame.size.height - ((highest *
                                                                      ((_scrollView.frame.size.height * screenHeight) / range)) -
                                                                     (lowest * ((_scrollView.frame.size.height * screenHeight) / range ))+
                                                                     offsetFromBottom));
    if (_highLabel == nil) {
        _highLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, highPoint.y - 5, self.yAxisWidth - 2, 8)];
        [_verticalView addSubview:_highLabel];
    }
    _highLabel.text = [NSString stringWithFormat:@"%ld", (long)(highest)];
    _highLabel.font = self.labelFont;
    _highLabel.textColor = [UIColor redColor];
    _highLabel.frame = CGRectMake(2, highPoint.y - 5, self.yAxisWidth - 2, 8);
    _highLabel.center = CGPointMake(_highLabel.center.x, highPoint.y);
    
    float midValue = ((highest - lowest) / 2) + lowest;
    CGPoint midPoint = CGPointMake((self.graphWidth / [_graphData count]),
                                   _scrollView.frame.size.height - ((midValue *
                                                                     ((_scrollView.frame.size.height * screenHeight) / range)) -
                                                                    (lowest * ((_scrollView.frame.size.height * screenHeight) / range ))+
                                                                    offsetFromBottom));
    if (_midLabel == nil) {
        _midLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, midPoint.y - 5, self.yAxisWidth - 2, 8)];
        [_verticalView addSubview:_midLabel];
    }
    _midLabel.text = [NSString stringWithFormat:@"%ld", (long)(midValue)];
    _midLabel.font = self.labelFont;
    _midLabel.textColor = self.labelFontColor;
    _midLabel.frame = CGRectMake(2, midPoint.y - 5, self.yAxisWidth - 2, 8);
    _midLabel.center = CGPointMake(_midLabel.center.x, midPoint.y);
    
    if (self.title != nil) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        titleLabel.text = self.title;
        titleLabel.textColor = [UIColor lightGrayColor];
        titleLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:titleLabel];
    }
}

- (NSDictionary *)workOutRangeFromArray:(NSArray *)array
{
    array = [array sortedArrayUsingSelector:@selector(compare:)];
    
    float lowest = [[array objectAtIndex:0] floatValue];
    
    float highest = [[array objectAtIndex:[array count] - 1] floatValue];
    
    float range = highest - lowest;
    
    NSDictionary *graphRange = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:lowest], @"lowest",
                                [NSNumber numberWithFloat:highest], @"highest",
                                [NSNumber numberWithFloat:range], @"range", nil];
    
    return graphRange;
}

#pragma mark - Drawing methods

- (void)createPointLabelForPoint:(CGPoint)point
                   withLabelText:(NSString *)string
{
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(point.x , point.y, 30, kPointLabelHeight)];
    tempLabel.textAlignment = NSTextAlignmentCenter;
    [tempLabel setTextColor:self.labelFontColor];
    [tempLabel setBackgroundColor:self.labelBackgroundColor];
    [tempLabel setFont:self.labelFont];
    [tempLabel setAdjustsFontSizeToFitWidth:YES];
    [tempLabel setMinimumScaleFactor:0.6];
    [_graphView addSubview:tempLabel];
    [tempLabel setCenter:CGPointMake(point.x, point.y - kPointLabelOffsetFromPointCenter)];
    [tempLabel setText:string];
}

- (void)createBackgroundVerticalBarWithXCoord:(CGPoint)xCoord
                          withXAxisLabelIndex:(NSInteger)indexNumber
{
    if (_graphDataLabels.count > 25 &&
        indexNumber < _graphDataLabels.count - 1 &&
        indexNumber % 5) {
        return;
    }
    CGFloat x = self.graphWidth % _graphData.count;
    
    // Update the frame size for graphData.count results that don't fit into graphWidth
    [_scrollView setContentSize:CGSizeMake(self.graphWidth - x, _scrollView.frame.size.height)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0 , 0, (self.graphWidth / [_graphData count]) - kGapBetweenBackgroundVerticalBars, _scrollView.frame.size.height * 2)];
    
    label.textAlignment = NSTextAlignmentCenter;
    
    [label setTextColor:self.labelXFontColor];
    [label setBackgroundColor:self.barColor];
    [label setMinimumScaleFactor:0.6];
    [label setFont:self.labelXFont];
    
    if (self.graphDataLabels) {
        label.text = [NSString stringWithFormat:@"%@",[self.graphDataLabels objectAtIndex:indexNumber]];
    }
    [label sizeToFit];
    [_graphView addSubview:label];
    
    [label setCenter:CGPointMake(xCoord.x, 10)];
}

- (void)drawLineBetweenPoint:(CGPoint)origin
                    andPoint:(CGPoint)destination
                  withColour:(UIColor *)colour
{
    CAShapeLayer *lineShape = nil;
    CGMutablePathRef linePath = nil;
    linePath = CGPathCreateMutable();
    lineShape = [CAShapeLayer layer];
    
    lineShape.lineWidth = self.strokeWidth;
    lineShape.lineCap = kCALineCapRound;;
    lineShape.lineJoin = kCALineJoinBevel;
    
    lineShape.strokeColor = [colour CGColor];
    
    NSInteger x = origin.x; NSInteger y = origin.y;
    NSInteger toX = destination.x; NSInteger toY = destination.y;
    CGPathMoveToPoint(linePath, NULL, x, y);
    CGPathAddLineToPoint(linePath, NULL, toX, toY);
    
    lineShape.path = linePath;
    CGPathRelease(linePath);
    
    [_graphView.layer addSublayer:lineShape];
    
    lineShape = nil;
}

- (void)drawCurvedLineBetweenPoints:(NSArray *)points
{
    float granularity = 100;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:points];
    
    [mutableArray insertObject:[points firstObject] atIndex:0];
    
    [mutableArray addObject:[points lastObject]];
    
    points = [NSArray arrayWithArray:mutableArray];
    
    [path moveToPoint:[self pointAtIndex:0 ofArray:points]];
    
    for (int index = 1; index < points.count - 2 ; index++) {
        
        CGPoint point0 = [self pointAtIndex:index - 1 ofArray:points];
        CGPoint point1 = [self pointAtIndex:index ofArray:points];
        CGPoint point2 = [self pointAtIndex:index + 1 ofArray:points];
        CGPoint point3 = [self pointAtIndex:index + 2 ofArray:points];
        
        for (int i = 1; i < granularity ; i++) {
            float t = (float) i * (1.0f / (float) granularity);
            float tt = t * t;
            float ttt = tt * t;
            
            CGPoint pi;
            pi.x = 0.5 * (2*point1.x+(point2.x-point0.x)*t + (2*point0.x-5*point1.x+4*point2.x-point3.x)*tt + (3*point1.x-point0.x-3*point2.x+point3.x)*ttt);
            pi.y = 0.5 * (2*point1.y+(point2.y-point0.y)*t + (2*point0.y-5*point1.y+4*point2.y-point3.y)*tt + (3*point1.y-point0.y-3*point2.y+point3.y)*ttt);
            
            if (pi.y > self.graphView.frame.size.height) {
                pi.y = self.graphView.frame.size.height;
            }
            else if (pi.y < 0){
                pi.y = 0;
            }
            
            if (pi.x > point0.x) {
                [path addLineToPoint:pi];
            }
        }
        
        [path addLineToPoint:point2];
    }
    
    [path addLineToPoint:[self pointAtIndex:[points count] - 1 ofArray:points]];
    
    CAShapeLayer *shapeView = [[CAShapeLayer alloc] init];
    
    shapeView.path = [path CGPath];
    
    shapeView.strokeColor = self.strokeColor.CGColor;
    shapeView.fillColor = [UIColor clearColor].CGColor;
    shapeView.lineWidth = self.strokeWidth;
    [shapeView setLineCap:kCALineCapRound];
    
    [self.graphView.layer addSublayer:shapeView];
}

- (CGPoint)pointAtIndex:(NSUInteger)index ofArray:(NSArray *)array
{
    NSValue *value = [array objectAtIndex:index];
    
    return [value CGPointValue];
}

- (void)drawPointswithStrokeColour:(UIColor *)stroke
                           andFill:(UIColor *)fill
                         fromArray:(NSMutableArray *)pointsArray
{
    NSMutableArray *pointCenterLocations = pointsArray;
    
    for (int i = 0; i < [pointCenterLocations count]; i++) {
        CGRect pointRect = CGRectMake(0, 0, 20, 20);
        
        JYGraphPoint *point = [[JYGraphPoint alloc] initWithFrame:pointRect];
        
        [point setStrokeColour:stroke];
        [point setFillColour:fill];
        
        [point setCenter:[[pointCenterLocations objectAtIndex:i] CGPointValue]];
        
        [point setBackgroundColor:[UIColor clearColor]];
        
        [_graphView addSubview:point];
    }
}

- (UIImage *)graphImage
{
    // These lines are to prevent cutting off of image
    // on watch. Related to scrollview frame vs content size
    CGRect scrollViewFrame = _scrollView.frame; // original frame to revert to
    _scrollView.frame = _graphView.frame;
    
    CGFloat scale = [self screenScale];
    
    if (scale > 1) {
        UIGraphicsBeginImageContextWithOptions(_graphView.frame.size, NO, scale);
    } else {
        UIGraphicsBeginImageContext(_graphView.frame.size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext: context];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Now revert it
    _scrollView.frame = scrollViewFrame;
    
    return viewImage;
}

- (float) screenScale {
    if ([ [UIScreen mainScreen] respondsToSelector: @selector(scale)] == YES) {
        return [ [UIScreen mainScreen] scale];
    }
    return 1;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_delegate) {
        [_delegate viewDidScroll:self offset:scrollView.contentOffset];
    }
}

@end
