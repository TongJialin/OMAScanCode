//
//  ScanViewController.m
//  ScanCode
//
//  Created by Oma-002 on 16/7/7.
//  Copyright © 2016年 com.tjl.org. All rights reserved.
//

#import "ScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ScanView.h"

#pragma mark -- 屏幕宽高
#define WIDTH [[UIScreen mainScreen] bounds].size.width
#define HEIGHT [[UIScreen mainScreen] bounds].size.height

#define previewRect CGRectMake((WIDTH - 250) / 2, (HEIGHT - 250 - 100)/2, 250, 250)

@interface ScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) AVCaptureDevice *device;

@property (strong, nonatomic) AVCaptureDeviceInput *input;

@property (strong, nonatomic) AVCaptureMetadataOutput *output;

@property (strong, nonatomic) AVCaptureSession *session;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) ScanView *scanView;

@property (strong, nonatomic) ScanQRCodeResult complete;

@end

@implementation ScanViewController

- (instancetype)initWithComplete:(ScanQRCodeResult)complete {
    self = [super init];
    if (self) {
        self.complete = complete;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_session && ![_session isRunning]) {
        [_session startRunning];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"二维码";
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:self.scanView];
    [self setupCamera];
}

-(ScanView *)scanView {
    
    if (!_scanView) {
        
        CGRect rect = previewRect;
        _scanView = [[ScanView alloc] initWithFrame:rect];
        _scanView.backgroundColor = [UIColor clearColor];
        [_scanView sweepAnimation];
    }
    return _scanView;
}

//添加背景照片
- (void)addBgImage {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT - 64)];
    imageView.image = [UIImage imageNamed:@"scan_code_box"];
    [self.view addSubview:imageView];
}

- (void)setupCamera
{
    if (![self authJudge]) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 耗时的操作
        // Device
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        // Input
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
        
        // Output
        _output = [[AVCaptureMetadataOutput alloc]init];
        //    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        // Session
        _session = [[AVCaptureSession alloc]init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:self.input])
        {
            [_session addInput:self.input];
        }
        
        if ([_session canAddOutput:self.output])
        {
            [_session addOutput:self.output];
        }
        
        // 条码类型 AVMetadataObjectTypeQRCode
        _output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新界面
            // Preview
            _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
            _preview.frame = CGRectMake(0, 0, WIDTH, HEIGHT);
            //_preview.frame = CGRectMake(0, 0, WIDTH, HEIGHT - 64);
            _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
            //            _preview.frame = self.view.bounds;
            [self.view.layer insertSublayer:self.preview atIndex:0];
            
            //            CGRect rect = CGRectMake((WIDTH - 250) / 2, (HEIGHT - 250 - 72)/2, 250, 250);
            _output.rectOfInterest = [_preview metadataOutputRectOfInterestForRect:previewRect];
            
            UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
            //UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT - 64)];
            maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
            [self.view addSubview:maskView];
            
            UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, WIDTH, HEIGHT)];
            [rectPath appendPath:[[UIBezierPath bezierPathWithRoundedRect:previewRect cornerRadius:1] bezierPathByReversingPath]];
            
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = rectPath.CGPath;
            
            maskView.layer.mask = shapeLayer;
            
            UILabel *explainLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, HEIGHT/2 + 110, WIDTH, 13)];
            explainLabel.text = @"将二维码放入取景框中即可自动扫描";
            explainLabel.textColor = [UIColor whiteColor];
            explainLabel.font = [UIFont systemFontOfSize:13];
            explainLabel.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:explainLabel];
            
            // Start
            [_session startRunning];
        });
    });
}

- (BOOL)authJudge {
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] <= 0) {
        NSLog(@"没有相机");
        return NO;
    }
    
    if([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
        NSLog(@"没有相机权限");
        return NO;
    }
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.timer invalidate];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    NSString *stringValue;
    
    if (metadataObjects != nil && [metadataObjects count] > 0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
        
        self.complete(stringValue);
        
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [_session stopRunning];
    [self.timer invalidate];
    NSLog(@"%@",stringValue);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
