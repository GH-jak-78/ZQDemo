//
//  UINavigationBar+BackgroundAlpha.m
//  ShiXingBang
//
//  Created by ZhaoQu on 16/7/19.
//  Copyright © 2016年 ZhaoQu. All rights reserved.
//

#import "UINavigationBar+BackgroundAlpha.h"
#import <objc/runtime.h>

@implementation UINavigationBar (BackgroundAlpha)

static char overlayKey;

- (UIView *)overlay
{
    return objc_getAssociatedObject(self, &overlayKey);
}

- (void)setOverlay:(UIView *)overlay
{
    objc_setAssociatedObject(self, &overlayKey, overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setBackgroundAlpha:(CGFloat )backgroundAlpha
{
    if (self.overlay == nil) {
        [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, -20, self.bounds.size.width, CGRectGetHeight(self.bounds) + 20)];
        self.overlay.backgroundColor = self.barTintColor ? self.barTintColor : [UIColor whiteColor];
        self.overlay.userInteractionEnabled = NO;
        self.overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self insertSubview:self.overlay atIndex:0];
    }
    if (backgroundAlpha < 1.0 && !self.shadowImage) {
        [self setShadowImage:[UIImage new]];
    }
    if (backgroundAlpha >= 1.0 && self.shadowImage) {
        [self setShadowImage:nil];
    }
    self.overlay.alpha = backgroundAlpha;
}

- (void)resetBackgroundAlpha
{
    [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:nil];
    [self.overlay removeFromSuperview];
    self.overlay = nil;
}

@end
