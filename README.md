# ZQDemo

# 1级标题
## 2级标题
### 3级标题
#### 4级标题
##### 5级标题
###### 6级标题

换<br>行

===
实隔线

---
虚隔线

    单行文本
    多行文本
    多行文本

`高亮`

http://www.baidu.com

[百度](http://www.baidu.com "悬停显示")

* 一级圆点
    * 二级圆点 
        * 三级圆点

>缩进
>>树
>>>二叉树
>>>>平衡二叉树
>>>>>满二叉树

![baidu](http://www.baidu.com/img/bdlogo.gif "百度logo")

        https://github.com/ 你的用户名 / 你的项目名 / raw / 分支名 / 存放图片的文件夹 / 该文件夹下的图片

[![baidu]](http://baidu.com)  
[baidu]:http://www.baidu.com/img/bdlogo.gif "百度Logo" 

```objective-c
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
            UIViewController *vc1 = [[UIViewController alloc]init];
            vc1.title = @"vc1";
            vc1.view.backgroundColor = [UIColor redColor];
            UIViewController *vc2 = [[UIViewController alloc]init];
            vc2.title = @"vc2";
            vc2.view.backgroundColor = [UIColor blueColor];
            UIViewController *vc3 = [[UIViewController alloc]init];
            vc3.title = @"vc3";
            vc3.view.backgroundColor = [UIColor greenColor];
            
            PaginationViewController *pvc = [[PaginationViewController alloc]initWithChildControllers:@[vc1, vc2, vc3]];
            [self.navigationController pushViewController:pvc animated:YES];
            break;
        }
        case 1:
        {
            InterLockViewController *vc = [[InterLockViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
            
            break;
        }
        case 2:
        {
            ClassesViewController *vc = [[ClassesViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
            
            break;
        }
        default:
            break;
    }
}
```
