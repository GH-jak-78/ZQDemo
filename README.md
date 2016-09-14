# ZQDemo

![baidu](/interlock.gif "interlock")

```objective-c
self.interlock = [[ZQInterlock alloc]initWithSourceView:self.classesView targetView:headerView translationHeight:200.0 - 64.0];
self.interlock.delegate = self;
[self.interlock registerScrollViews:@[self.classesView.verticalView, self.classesView.contentView]];
```
