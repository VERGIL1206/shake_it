//
//  fanyi.m
//  ST
//
//  Created by VERGIL on 2018/2/6.
//  Copyright © 2018年 jonh. All rights reserved.
//

#import "fanyi.h"
#import "YYYViewController.h"

@interface fanyi ()

@end

@implementation fanyi

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.layer.contents = (id)[UIImage imageNamed:@"BG_2"].CGImage;
    
    NSString * fanyiwenzhang = [[NSString alloc]init];
    fanyiwenzhang = _chuanzhi2;
    
    NSMutableDictionary *attDic = [NSMutableDictionary dictionary];
    [attDic setValue:[UIFont systemFontOfSize:16] forKey:NSFontAttributeName];      // 字体大小
    //    [attDic setValue:[UIColor redColor] forKey:NSForegroundColorAttributeName];     // 字体颜色
    [attDic setValue:@5 forKey:NSKernAttributeName];                                // 字间距
    //    [attDic setValue:[UIColor cyanColor] forKey:NSBackgroundColorAttributeName];    // 设置字体背景色
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:_chuanzhi2 attributes:attDic];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 20;                                                          // 设置行之间的间距
    [attStr addAttribute:NSParagraphStyleAttributeName value:style range: NSMakeRange(0, _chuanzhi2.length)];
    
    CGFloat contentH = [attStr boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
    // 自动计算文本高度
    
    
    UILabel *txtLbl = [[UILabel alloc] init];
    txtLbl.frame = CGRectMake(25, 50, self.view.bounds.size.width-50, 0);
    txtLbl.numberOfLines = 0;
    txtLbl.attributedText = attStr;
    txtLbl.textAlignment = UITextAlignmentCenter;
    [txtLbl sizeToFit];
    CGSize size = [txtLbl sizeThatFits:CGSizeMake(txtLbl.frame.size.width, MAXFLOAT)];
    
    UIScrollView *sv = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, self.view.bounds.size.height/2*1.5)];
    
    sv.contentInset = UIEdgeInsetsMake(0, 0, size.height+30, 0);
    
    [sv addSubview:txtLbl];
    
    [self.view addSubview:sv];
    
    
    
    UIButton * back = [UIButton buttonWithType:0];
    back.frame = CGRectMake(30,self.view.bounds.size.height/10*9,24,24);
    back.layer.contents = (id)[UIImage imageNamed:@"返回"].CGImage;
    [back addTarget:self action:@selector(fanhui1) forControlEvents:1];
    [self.view addSubview:back];
    
    
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
