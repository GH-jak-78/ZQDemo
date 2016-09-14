# ZQDemo

### ZQInterlock

实现了现在APP很流行的滚动TableView,让上部分视图跟着隐藏或只显示一个Tabbar,效果如下:

![baidu](/interlock.gif "interlock")


只需两行代码就可实现这效果,不影响原先视图布局,操作很流畅.

```objective-c
self.interlock = [[ZQInterlock alloc]initWithSourceView:self.paginationController.view targetView:headerView translationHeight:200.0 - 64.0];
[self.interlock registerScrollViews:@[vc1.tableView, vc2.tableView, vc3.tableView]];
```

根据实现原理我称之为联动,可能不是流行的说法,网友知道的也可以告诉我!

E-mail:jak_78@sina.com