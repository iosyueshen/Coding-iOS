//
//  AudioRecordView.m
//  audiodemo
//
//  Created by sumeng on 7/30/15.
//  Copyright (c) 2015 sumeng. All rights reserved.
//

#import "AudioRecordView.h"
#import "AudioManager.h"
#import <QuartzCore/QuartzCore.h>

@interface AudioRecordView () <AudioManagerDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) AudioRecordViewTouchState touchState;

@property (nonatomic, strong) UIView *recordBgView;
@property (nonatomic, strong) UIView *spreadView;
@property (nonatomic, strong) UIView *flashView;

@end

@implementation AudioRecordView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _isRecording = NO;
        
        _recordBgView = [[UIView alloc] initWithFrame:CGRectMake(-15, -15, self.frame.size.width+30, self.frame.size.height+30)];
        _recordBgView.backgroundColor = [UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:0.1f];
        _recordBgView.layer.cornerRadius = _recordBgView.frame.size.width/2;
        _recordBgView.layer.borderColor = [[UIColor colorWithRGBHex:0xdddddd] CGColor];
        _recordBgView.layer.borderWidth = 1;
        _recordBgView.hidden = YES;
        [self addSubview:_recordBgView];
        
        _spreadView = [[UIView alloc] initWithFrame:_recordBgView.frame];
        _spreadView.layer.cornerRadius = _recordBgView.frame.size.width/2;
        _spreadView.layer.borderColor = [[UIColor colorWithRGBHex:0xdddddd] CGColor];
        _spreadView.layer.borderWidth = 1;
        _spreadView.alpha = 0;
        [self addSubview:_spreadView];
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.backgroundColor = [UIColor colorWithRGBHex:0x2faeea];
        _imageView.layer.cornerRadius = self.frame.size.width/2;
        _imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_imageView];
        
        _flashView = [[UIView alloc] initWithFrame:self.bounds];
        _flashView.backgroundColor = [UIColor whiteColor];
        _flashView.layer.cornerRadius = _flashView.frame.size.width/2;
        _flashView.alpha = 0;
        [self addSubview:_flashView];
        
        [self addTarget:self action:@selector(onTouchDown:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(onTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(onTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)record {
    [self stop];
    
    [AudioManager shared].delegate = self;
    [[AudioManager shared] recordWithValidator:_validator];
}

- (void)stop {
    _isRecording = NO;
    [self stopAnimation];
    [[AudioManager shared] stopRecord];
}

- (void)onTouchDown:(id)sender {
    [self record];
}

- (void)onTouchUpInside:(id)sender {
    [self stop];
}

- (void)onTouchUpOutside:(id)sender {
    [self stop];
}

#pragma mark - touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    _touchState = AudioRecordViewTouchStateInside;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    BOOL touchInside = [self pointInside:[touch locationInView:self] withEvent:nil];
    BOOL touchStateChanged = NO;
    if (_touchState == AudioRecordViewTouchStateInside && !touchInside) {
        _touchState = AudioRecordViewTouchStateOutside;
        touchStateChanged = YES;
    }
    else if (_touchState == AudioRecordViewTouchStateOutside && touchInside) {
        _touchState = AudioRecordViewTouchStateInside;
        touchStateChanged = YES;
    }
    if (touchStateChanged) {
        if (_delegate && [_delegate respondsToSelector:@selector(recordView:touchStateChanged:)]) {
            [_delegate recordView:self touchStateChanged:_touchState];
        }
    }
}

#pragma mark - Animation

- (void)startAnimation {
    _recordBgView.hidden = NO;
    _spreadView.alpha = 1.0f;
    _spreadView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    _flashView.alpha = 0.6f;
    
    [UIView beginAnimations:@"RecordAnimation" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:2.0f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationRepeatCount:FLT_MAX];
    
    _flashView.alpha = 0;
    _spreadView.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
    _spreadView.alpha = 0;
    
    [UIView commitAnimations];
}

- (void)stopAnimation {
    [_flashView.layer removeAllAnimations];
    [_spreadView.layer removeAllAnimations];
    
    _recordBgView.hidden = YES;
    _spreadView.alpha = 0;
    _flashView.alpha = 0;
}

#pragma mark - AudioManagerDelegate

- (void)didAudioRecordStarted:(AudioManager *)am {
    _isRecording = YES;
    [self startAnimation];
    
    if (_delegate && [_delegate respondsToSelector:@selector(recordViewRecordStarted:)]) {
        [_delegate recordViewRecordStarted:self];
    }
}

- (void)didAudioRecording:(AudioManager *)am volume:(double)volume {
    if (_delegate && [_delegate respondsToSelector:@selector(recordView:volume:)]) {
        [_delegate recordView:self volume:volume];
    }
}

- (void)didAudioRecordStoped:(AudioManager *)am file:(NSString *)file duration:(NSTimeInterval)duration successfully:(BOOL)successfully {
    NSLog(@"didAudioRecordStoped");
    if (_delegate && [_delegate respondsToSelector:@selector(recordViewRecordFinished:file:duration:)]) {
        [_delegate recordViewRecordFinished:self file:file duration:duration];
    }
}

- (void)didAudioRecord:(AudioManager *)am err:(NSError *)err {
    _isRecording = NO;
    [self stop];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:err.localizedDescription delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

@end
