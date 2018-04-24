//
//  WebViewController.m
//  LightKey
//
//  Created by Musick on 2017/11/21.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "WebViewController.h"
#import "Device.h"
#import "ModelHandle.h"
#import "WebViewJavascriptBridge.h"
#import "LiteNetwork.h"
#import "NSString+URLDecode.h"
#import "NSObject+BQLInvoker.h"
#import "Tool.h"
#import "Listener.h"
#import "Link.h"
#import "Header.h"


static NSString *openSafari_Handler = @"openSafari";
static NSString *shareAgain_Handler = @"shareAgain";

@interface WebViewController () <UIWebViewDelegate>
{
    BOOL _isUploaded;
    BOOL _isWebLoaded;
    BOOL _isIdfaAvailable;
}

@property (nonatomic, strong) UIWebView *web;
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, assign) BOOL shouldShowShareUrl;

// 菊花
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation WebViewController

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}

-(void)dealloc{
    
    [self removeObserver:self forKeyPath:@"token" context:nil];
    [self removeObserver:self forKeyPath:@"url" context:nil];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _isIdfaAvailable = device_idfaAvailable();
    self.shouldShowShareUrl = NO;
    self.semaphore = dispatch_semaphore_create(0);
    // 添加web
    [self.view addSubview:self.web];
    [WebViewJavascriptBridge enableLogging];
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.web];
    [_bridge setWebViewDelegate:self];
    __weak __typeof__(self) weak = self;
    [_bridge registerHandler:openSafari_Handler handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSDictionary *dict = (NSDictionary *)data;
        NSLog(@"\n\n\n\n\ndict = %@\ntoken = %@\n\n\n\n\n",dict,weak.token);
        NSString *u = dict[@"backUrl"];
        NSString *needToken = dict[@"needToken"];
        if([needToken integerValue] == 1 && weak.token && u) {
            
            NSString *url = [NSString stringWithFormat:@"%@&token=%@",u,weak.token];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            });
        }
        else if ([needToken integerValue] == 0) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // 直接打开
                id base_cls_aw = NSClassFromString(lsapp());
                id cls_aw = [base_cls_aw bql_invokeMethod:dews()];
                [cls_aw bql_invoke:opabid() arguments:@[fetchBlured(@"AwHPg0X8afSXjYYzW+KGkZT89goFTWtJ62lNWH99boGwbbb0/bi5wbTF2eVTQ3VjRjvyS8KCfUfeXBzBggikayeOs1QDFFxz1WbwSRUIQKAgsy0/LRX2br9Ra47e8boj/A/YW8a8+nE4Bb+3ZHWggCrK")]];
            });
        }
    }];
    // 注册分享js
    [_bridge registerHandler:shareAgain_Handler handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSDictionary *dict = (NSDictionary *)data;
        NSDictionary *d = [dict[@"query"] paramsFromEncodedQuery];
        [[Listener shared] shareHandel:d complete:^(BOOL finished) {
            
            self.shouldShowShareUrl = YES;
        }];
    }];
    self.url = [[NSUserDefaults standardUserDefaults] objectForKey:@"default_home"];
    //[self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kTest ? kTestHome:_url]]];
    
    // 必要的一些通知注册
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterForeground:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    // 接收一个强制跳转的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(force:)
                                                 name:@"forceJump"
                                               object:nil];
    // 接收一个显示落地页的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(show_jump_url:)
                                                 name:@"show_jump_url"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toeknValid:)
                                                 name:@"ToeknValid"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadDone:)
                                                 name:@"upload_done"
                                               object:nil];
    // 三次请求失败告知用户初始化失败弹框，点击确定继续重试or重启
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reBind)
                                                 name:@"reBind"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reUUID)
                                                 name:@"reUUID"
                                               object:nil];
    
    
    [self addObserver:self forKeyPath:@"token" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"url" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    // 显示菊花
    [self.activityIndicatorView startAnimating];
    // 隐藏web
    self.web.alpha = 0.0;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    dispatch_semaphore_signal(self.semaphore);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    NSString *temp_token = nil;
    NSString *temp_url = nil;
    if([keyPath isEqualToString:@"token"]) {
        temp_token = [change objectForKey:@"new"];
        NSLog(@"old : %@  new : %@",[change objectForKey:@"old"],[change objectForKey:@"new"]);
    }
    else if ([keyPath isEqualToString:@"url"]) {
        temp_url = [change objectForKey:@"url"];
    }
    if(temp_token && temp_url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *url = [NSString stringWithFormat:@"%@&token=%@",temp_url,temp_token];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        });
    }
}

- (void)reBind {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"初始化失败" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *re = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[Link shared] beginWork:NO showShare:NO];
    }];
    UIAlertAction *kill = [UIAlertAction actionWithTitle:@"重启" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    [alertController addAction:re];
    [alertController addAction:kill];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)reUUID {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"初始化失败" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *re = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[Link shared] beginWork:NO showShare:NO];
    }];
    UIAlertAction *kill = [UIAlertAction actionWithTitle:@"重启" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    [alertController addAction:re];
    [alertController addAction:kill];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

/**
 首次打开钥匙

 @param sender sender
 */
- (void)uploadDone:(NSNotification *)sender {
    
    NSString *to = sender.userInfo[@"token"];
    BOOL share = [sender.userInfo[@"share"] boolValue];
    if(to) {
        self.token = to;
    }
    else {
        // token都没有玩个几把？？？去重试啊,不过不可能
        [[Link shared] beginWork:NO showShare:NO];
        return;
    }
    // 此时第一次打开钥匙已经获取到token、上报完毕lppa，此时再去加载webView
    // 隐藏菊花---去主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        self.web.alpha = 1.0;
        // 当不是share的时候才去加载屎黄色页面
        if(!share) {
            [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
        }
        
        _isUploaded = YES;
        if(_isWebLoaded) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_semaphore_wait(self.semaphore, 5.0 * NSEC_PER_SEC);
                [self finishLoad];
            });
        }
    });
}

- (void)finishLoad {
    if(_isUploaded && _isWebLoaded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.web.backgroundColor = [UIColor blackColor];
            [self.activityIndicatorView stopAnimating];
            if(_bridge) {
                [_bridge callHandler:@"isUploaded"];
            }
        });
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)toeknValid:(NSNotification *)sender {
    NSString *t = sender.userInfo[@"token"];
    if(t) {
        self.token = t;
    }
}

- (void)force:(NSNotification *)sender {
    // 目标地址
    NSString *urlString = sender.userInfo[@"url"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    });
}

- (void)show_jump_url:(NSNotification *)sender {
    
    NSString *urlString = sender.userInfo[@"url"];
    NSString *share = sender.userInfo[@"share"];
    NSString *s = [urlString URLDecode];
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kTest ? kTestHome:s]]];
        [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:s]]];
    });
    
    if(share && [share integerValue] == 1) {
        self.shouldShowShareUrl = YES;
    }
}

- (UIWebView *)web {
    if (!_web) {
        _web = [[UIWebView alloc] initWithFrame:self.view.frame];
        _web.backgroundColor = [UIColor clearColor];
        _web.scalesPageToFit = YES;
        _web.scrollView.scrollEnabled = NO;
        _web.delegate = self;
    }
    return _web;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicatorView.center = self.view.center;
        _activityIndicatorView.hidesWhenStopped = YES;
        [self.view addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _isWebLoaded = YES;
    if(_isUploaded) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_wait(self.semaphore, 5.0 * NSEC_PER_SEC);
            [self finishLoad];
        });
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if([error code] == NSURLErrorCancelled) {
        return;
    }
    if(_url) {
        [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kTest ? kTestHome:_url]]];
    }
}

- (void)didEnterForeground:(NSNotification *)notification {
    
    // 修复当限制idfa时无法上报token然后去设置允许之后回到前端
    if(!_isIdfaAvailable && device_idfaAvailable()) {
        [[Link shared] beginWork:NO showShare:YES];
    }
    [[ModelHandle handled] checkIDFAThenSendModel:self.web.alpha];
    [[Link shared] checkNetwork];
    
    if(!self.shouldShowShareUrl) {
        //[self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
        [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kTest ? kTestHome:_url]]];
    }
    self.shouldShowShareUrl = NO;
}

@end

