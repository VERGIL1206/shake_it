//
//  YYYViewController.m
//  ST
//                          
//  Created by VERGIL on 2018/1/11.
//  Copyright © 2018年 jonh. All rights reserved.
//

#import "YYYViewController.h"
#import <AVQuery.h>
#import "AVObject.h"
#import "AVFile.h"
#import <AVFoundation/AVFoundation.h>
#import "fanyi.h"




@interface YYYViewController ()
@property (nonatomic, strong)  NSString * gushiname;
@property (nonatomic, strong)  NSString * mingzi1;
@property (nonatomic, strong)  NSString * wenzhang1;
@property (nonatomic, strong)  NSString * ciyujieshi;
@property (nonatomic, strong)  NSString * fanyi;
@property (nonatomic, copy)    AVPlayer * player;
@property (nonatomic, strong)  AVFile * yinyue1;




@end


@implementation YYYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    self.view.backgroundColor = [UIColor grayColor];
    self.view.layer.contents = (id)[UIImage imageNamed:@"BG_2"].CGImage;
    
    
    
    _mingzi1  = [_chuanzhi objectForKey:@"name"];
    _wenzhang1  = [_chuanzhi objectForKey:@"wenzhang"];
    _ciyujieshi  = [_chuanzhi objectForKey:@"ciyujieshi"];
    _yinyue1  = [_chuanzhi objectForKey:@"shakegushi"];
    _fanyi  = [_chuanzhi objectForKey:@"fanyi"];
    
    


    
    NSMutableDictionary *attDic = [NSMutableDictionary dictionary];
    [attDic setValue:[UIFont systemFontOfSize:16] forKey:NSFontAttributeName];      // 字体大小
//    [attDic setValue:[UIColor redColor] forKey:NSForegroundColorAttributeName];     // 字体颜色
    [attDic setValue:@5 forKey:NSKernAttributeName];                                // 字间距
//    [attDic setValue:[UIColor cyanColor] forKey:NSBackgroundColorAttributeName];    // 设置字体背景色
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:_wenzhang1 attributes:attDic];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 20;                                                          // 设置行之间的间距
    [attStr addAttribute:NSParagraphStyleAttributeName value:style range: NSMakeRange(0, _wenzhang1.length)];
    
    CGFloat contentH = [attStr boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
    // 自动计算文本高度
    

    UILabel *txtLbl = [[UILabel alloc] init];
    txtLbl.frame = CGRectMake(25, 20, self.view.bounds.size.width-50, 0);
    txtLbl.numberOfLines = 0;
    txtLbl.attributedText = attStr;
    [txtLbl sizeToFit];
    CGSize size = [txtLbl sizeThatFits:CGSizeMake(txtLbl.frame.size.width, MAXFLOAT)];

    
    UIScrollView *sv = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 60, self.view.bounds.size.width, self.view.bounds.size.height/2-50)];
    
    sv.contentInset = UIEdgeInsetsMake(0, 0, size.height+30, 0);
    
    [sv addSubview:txtLbl];
    
    [self.view addSubview:sv];
    
    
    
    NSMutableDictionary *attDic2 = [NSMutableDictionary dictionary];
    [attDic2 setValue:[UIFont systemFontOfSize:16] forKey:NSFontAttributeName];      // 字体大小
    [attDic2 setValue:[UIColor blueColor] forKey:NSForegroundColorAttributeName];     // 字体颜色
    [attDic2 setValue:@5 forKey:NSKernAttributeName];                                // 字间距
    //    [attDic setValue:[UIColor cyanColor] forKey:NSBackgroundColorAttributeName];    // 设置字体背景色
    NSMutableAttributedString *attStr2 = [[NSMutableAttributedString alloc] initWithString:_ciyujieshi attributes:attDic2];
    
    NSMutableParagraphStyle *style2 = [[NSMutableParagraphStyle alloc] init];
    style2.lineSpacing = 10;                                                          // 设置行之间的间距
    [attStr2 addAttribute:NSParagraphStyleAttributeName value:style2 range: NSMakeRange(0, _ciyujieshi.length)];
    
    CGFloat contentH2 = [attStr2 boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;                                                    // 自动计算文本高度
    UILabel *txtLbl2 = [[UILabel alloc] init];
    txtLbl2.frame = CGRectMake(20, 20, self.view.bounds.size.width-80, 0);
    txtLbl2.numberOfLines = 0;
    txtLbl2.attributedText = attStr2;
    [txtLbl2 sizeToFit];

    CGSize size2 = [txtLbl2 sizeThatFits:CGSizeMake(txtLbl2.frame.size.width, MAXFLOAT)];
    
    if ([UIScreen mainScreen].bounds.size.width == 320 && [UIScreen mainScreen].bounds.size.height == 480) {
        UIScrollView *sv2 = [[UIScrollView alloc]initWithFrame:CGRectMake(20, 50+self.view.bounds.size.height/2, self.view.bounds.size.width-40, 125)];
        sv2.contentInset = UIEdgeInsetsMake(0, 0, size2.height+30, 0);
        //    sv2.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"kuang"]];
        sv2.layer.contents = (id)[UIImage imageNamed:@"kuang"].CGImage;
        [sv2 addSubview:txtLbl2];
        
        [self.view addSubview:sv2];
        
    }else {
        UIScrollView *sv2 = [[UIScrollView alloc]initWithFrame:CGRectMake(20, 50+self.view.bounds.size.height/2, self.view.bounds.size.width-40, 216)];
        sv2.contentInset = UIEdgeInsetsMake(0, 0, size2.height+30, 0);
        //    sv2.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"kuang"]];
        sv2.layer.contents = (id)[UIImage imageNamed:@"kuang"].CGImage;
        [sv2 addSubview:txtLbl2];
        
        [self.view addSubview:sv2];
    }
    
    
    
   
    
    
    
    
    UIButton * playm = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width/10*8,self.view.bounds.size.height/10*9,36,36)];
//    [playm setTitle:@"播放" forState:(0)];
//    playm.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"播放"]];
    playm.layer.contents = (id)[UIImage imageNamed:@"播放"].CGImage;
    [playm addTarget:self action:@selector(playmusic) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playm];
    
    
    
    UIButton * fanyi = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width/10*8-50,self.view.bounds.size.height/10*9,36,36)];
//    fanyi.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"翻译"]];
    fanyi.layer.contents = (id)[UIImage imageNamed:@"翻译"].CGImage;
    
    [fanyi addTarget:self action:@selector(tiaozhuanfanyi) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:fanyi];
    
    
    
    
    
    
    
    
    UIButton * back = [UIButton buttonWithType:0];
    back.frame = CGRectMake(30,self.view.bounds.size.height/10*9,36,36);
    back.layer.contents = (id)[UIImage imageNamed:@"返回"].CGImage;
    [back addTarget:self action:@selector(fanhui1) forControlEvents:1];
    [self.view addSubview:back];
    
    
    
     
     
    

    
    UILabel *gushimingzi = [[UILabel alloc]initWithFrame:CGRectMake(30, 30, 500, 30)];
    gushimingzi.text = _mingzi1;
    
    [self.view addSubview:gushimingzi];
    
    
}

-(void)playmusic{
    //    NSURL * url = [[NSURL alloc]initFileURLWithPath:[[NSBundle mainBundle]pathForResource:_yinyue1 ofType:@"mp3"]];
    NSURL * url  = [NSURL URLWithString:_yinyue1.url];

    AVPlayerItem * songItem = [[AVPlayerItem alloc]initWithURL:url];
    _player = [[AVPlayer alloc]initWithPlayerItem:songItem];
    _player = [[AVPlayer alloc] initWithURL:url];  
    _player.volume = 1;

    [_player play];
    
}




-(void)tiaozhuanfanyi{
    fanyi * fanyi1 = [[fanyi alloc]init];
    fanyi1.chuanzhi2 = _fanyi;

    [self presentViewController:fanyi1 animated:YES completion:^{
    }];
    
}




-(void)fanhui1{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    }
*/

@end
