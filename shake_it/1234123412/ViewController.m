//
//  ViewController.m
//  物理仿真 碰撞 重力 陀螺仪
//
//  Created by jonh on 2017/11/22.
//  Copyright © 2017年 jonh. All rights reserved.
//
#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "YYYViewController.h"
#import <AVOSCloud.h>
#import <AVQuery.h>
#import "AVObject.h"
#import <AudioToolbox/AudioToolbox.h>


@interface ViewController ()
{
    //物理仿真 动画
    UIDynamicAnimator * _dynamicAnimator;
    //物理仿真 行为
    UIDynamicItemBehavior * _dynamicItemBehavior;
    //重力 行为
    UIGravityBehavior * _gravityBehavior;
    //碰撞 行为
    UICollisionBehavior * _collisionBehavior;
}
/// 传感器
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSArray * result;
@property (nonatomic, strong) NSMutableArray * chuansongmingzi;
@property (nonatomic, strong) NSMutableArray * mingzi1;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createDynamic];
   
    [self useGyroPush];
    
    [AVOSCloud setApplicationId:kLID
                      clientKey:kLKEY];

    
    
    
    AVQuery *query = [AVQuery queryWithClassName:@"shake_it"];
    _result = [query findObjects];

    
    self.view.layer.contents = (id)[UIImage imageNamed:@"BG_2"].CGImage;

    
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
//    [self becomeFirstResponder];
    
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    NSLog(@"开始摇动");
//    [self animation];
    [self shakeshake];
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventSubtypeMotionShake ) {
        NSLog(@"摇动结束");

    }
}

- (void)shakeshake {
    
    _chuansongmingzi = [[NSMutableArray alloc] init];
    
    while ([_chuansongmingzi count] < 1) {
        int r = arc4random()%[_result count];
        [_chuansongmingzi addObject:[_result objectAtIndex:r]];
        YYYViewController * nihaoma = [[YYYViewController alloc]init];
        nihaoma.chuanzhi = [_result objectAtIndex:r];
        [self presentViewController:nihaoma animated:YES completion:^{
        }];
        
    }
}



- (void)createItem{
    int x = arc4random() % (int)self.view.frame.size.width; //随机X坐标
    int size = arc4random() % 30 + 20;//随机大小
    NSArray * imageArray = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12",@"13",@"14",@"15",@"16",@"17",@"18",@"19",@"20",@"21",@"22",@"23",@"24",@"25" ];
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(x, 100, size, size)];
    imageView.userInteractionEnabled = YES;
    imageView.image = [UIImage imageNamed:imageArray[arc4random() % imageArray.count]];
    [self.view addSubview:imageView];
    //让imageView遵循行为
    [_dynamicItemBehavior addItem:imageView];
    [_gravityBehavior addItem:imageView];
    [_collisionBehavior addItem:imageView];
    UITapGestureRecognizer *taps = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeItem:)];
    [imageView addGestureRecognizer:taps];
    
    
}
- (void)removeItem:(UITapGestureRecognizer *)taps{
    UIView *tempViews = taps.view;
    [_dynamicItemBehavior removeItem:tempViews];
    [_gravityBehavior removeItem:tempViews];
    [_collisionBehavior removeItem:tempViews];
    [tempViews removeFromSuperview];
  
}
- (void)useGyroPush{
    //初始化全局管理对象
    CMMotionManager *manager = [[CMMotionManager alloc] init];
    self.motionManager = manager;
    //判断传感器是否可用
    if ([self.motionManager isDeviceMotionAvailable]) {
        ///设备 运动 更新 间隔
        manager.deviceMotionUpdateInterval = 0.1;
        ///启动设备运动更新队列
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                                withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                                                    double gravityX = motion.gravity.x;
                                                    double gravityY = motion.gravity.y;
                                                    // double gravityZ = motion.gravity.z;
                                                    // 获取手机的倾斜角度(z是手机与水平面的夹角， xy是手机绕自身旋转的角度)：
                                                    //double z = atan2(gravityZ,sqrtf(gravityX * gravityX + gravityY * gravityY))  ;
                                                    double xy = atan2(gravityX, gravityY);
                                                    // 计算相对于y轴的重力方向
                                                    _gravityBehavior.angle = xy-M_PI_2;
                                                    
                                                }];
        
    }
}
- (void)createDynamic
{
    //创建现实动画 设定动画模拟区间。self.view : 地球
    _dynamicAnimator = [[UIDynamicAnimator alloc]initWithReferenceView:self.view];
    //创建物理仿真行为
    _dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[]];
    //设置弹性系数,数值越大,弹力值越大
    _dynamicItemBehavior.elasticity = 0.8;
    //重力行为
    _gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[]];
    //碰撞行为
    _collisionBehavior = [[UICollisionBehavior alloc]initWithItems:@[]];
    //开启刚体碰撞
    _collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    //将行为添加到物理仿动画中
    [_dynamicAnimator addBehavior:_dynamicItemBehavior];
    [_dynamicAnimator addBehavior:_gravityBehavior];
    [_dynamicAnimator addBehavior:_collisionBehavior];
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self createItem];
}
- (IBAction)action_start:(UIButton *)sender {
    [sender removeFromSuperview];
    for (int i=0 ; i<50; i++) {
        [self createItem];
    }
}
@end
