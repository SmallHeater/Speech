//
//  ViewController.m
//  Speech
//
//  Created by xianjunwang on 2017/10/31.
//  Copyright © 2017年 xianjunwang. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>



@interface ViewController ()<SFSpeechRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *resultLabel;
@property (strong, nonatomic) IBOutlet UIButton *recordBtn;
@property(nonatomic,strong)SFSpeechRecognizer * recognizer ;
//语音识别功能
@property(nonatomic,strong)SFSpeechAudioBufferRecognitionRequest * recognitionRequest ;
@property(nonatomic,strong)SFSpeechRecognitionTask * recognitionTask ;
@property(nonatomic,strong)AVAudioEngine * audioEngine ;


@end

@implementation ViewController

#pragma mark  ----  生命周期函数

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    self.recordBtn.enabled = false;
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        bool isButtonEnabled = false;
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                isButtonEnabled = true;
                NSLog(@"可以语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                isButtonEnabled = false;
                NSLog(@"用户被拒绝访问语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                isButtonEnabled = false;
                NSLog(@"不能在该设备上进行语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                isButtonEnabled = false;
                NSLog(@"没有授权语音识别");
                break;
            default:
                break;
        }
        self.recordBtn.enabled = isButtonEnabled;
    }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark  ----  代理方法
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    
    if (available) {
        self.recordBtn.enabled = YES;
    }else{
        
        self.recordBtn.enabled = NO;
    }
}


#pragma mark  ----  自定义函数

- (IBAction)recordBtnClicked:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        
        //开始录音
        if ([self.audioEngine isRunning]) {
            [self.audioEngine stop];
            [self.recognitionRequest endAudio];
            self.recordBtn.enabled = YES;
        }else{
            [self startRecording];
        }
    }
    else{
    
        //停止录音
    }
}


- (void)startRecording{
    
    if (self.recognitionTask) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    bool  audioBool = [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    bool  audioBool1= [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
    bool  audioBool2= [audioSession setActive:true withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    if (audioBool || audioBool1||  audioBool2) {
        NSLog(@"可以使用");
    }else{
        NSLog(@"这里说明有的功能不支持");
    }
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc]init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    
    self.recognitionRequest.shouldReportPartialResults = true;
    
    
    //开始识别任务
    self.recognitionTask = [self.recognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        bool isFinal = false;
        if (result) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.resultLabel.text = [[result bestTranscription] formattedString]; //语音转文本
            });
            
            isFinal = [result isFinal];
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            self.recognitionRequest = nil;
            self.recognitionTask = nil;
            self.recordBtn.enabled = true;
        }
    }];
    
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    [self.audioEngine prepare];
    bool audioEngineBool = [self.audioEngine startAndReturnError:nil];
    NSLog(@"%d",audioEngineBool);
    self.resultLabel.text = @"语音转换中。。。。。。";
}


#pragma mark  ----  懒加载
-(SFSpeechRecognizer *)recognizer{

    if (!_recognizer) {
        
        //将设备识别语音为中文
        NSLocale *cale = [[NSLocale alloc]initWithLocaleIdentifier:@"zh-CN"];
        _recognizer = [[SFSpeechRecognizer alloc]initWithLocale:cale];
        //设置代理
        _recognizer.delegate = self;
    }
    return _recognizer;
}

 //创建录音引擎
-(AVAudioEngine *)audioEngine{

    if (!_audioEngine) {
        
        _audioEngine = [[AVAudioEngine alloc]init];
    }
    return _audioEngine;
}
@end
