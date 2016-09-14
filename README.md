
### ZQInterlock

实现了现在APP很流行的滚动TableView,让上部分视图跟着隐藏或只显示一个Tabbar,效果如下:

![interlock](/GIF/ClassesView-Interlock.gif "interlock")
![interlock](/GIF/Pagination-Interlock.gif "interlock")

只需两行代码就可实现这效果,不影响原先视图布局,操作很流畅.

```objective-c
self.interlock = [[ZQInterlock alloc]initWithSourceView:self.paginationController.view targetView:headerView translationHeight:200.0 - 64.0];
[self.interlock registerScrollViews:@[vc1.tableView, vc2.tableView, vc3.tableView]];
```

根据实现原理我称之为联动,可能不是流行的说法,网友知道的也可以告诉我!

E-mail:jak_78@sina.com


### ZQPaginationController
封装好的分页导航控制器

可以在这基础上继承使用,也可作为其它控制器的属性或成员变量使用,但这时需手工将该控制加到其父控制器的子控制器集中,不管哪种用法,都要自已去管理其的itemView的布局,效果见上面的gif图

```objective-c
[self.view addSubview:self.itemsView];
[self.itemsView mas_makeConstraints:^(MASConstraintMaker *make) {
make.top.offset(0);
make.left.right.offset(0);
make.height.offset(44);
}];
```

```objective-c
TableViewController *vc1 = [[TableViewController alloc]init];
vc1.title = @"vc1";
TableViewController *vc2 = [[TableViewController alloc]init];
vc2.title = @"vc2";
TableViewController *vc3 = [[TableViewController alloc]init];
vc3.title = @"vc3";

self.paginationController = [[ZQPaginationController alloc]initWithChildControllers:@[vc1, vc2, vc3]];
[headerView addSubview:self.paginationController.itemsView];
[self.view addSubview:self.paginationController.view];
```


### ZQClassesView

封装好的分类视图


### UINavigationBar+BackgroundAlpha
设置导航栏背影透明度的分类

监听滚动的距离按比率设置
```objective-c
[self.navigationController.navigationBar setBackgroundAlpha:translationHeight / (200.0 - 64.0)];
```
另在viewWillAppear初始化和viewWillDisappear中重置设置
```objective-c
- (void)viewWillAppear:(BOOL)animated
{
[super viewWillAppear:animated];
[self interlock:self.interlock didTranslationWithTranslationHeight:self.interlock.currentTranslationHeight];
}

- (void)viewWillDisappear:(BOOL)animated
{
[super viewWillDisappear:animated];
[self.navigationController.navigationBar resetBackgroundAlpha];
}
```

