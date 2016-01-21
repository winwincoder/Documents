//
//  ViewController.swift
//  SpeexDemo
//
//  Created by user on 14-10-15.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var speech: SimpleSpeech?
    var ipAdress:UITextField!
    var stateLb:UILabel!
    var localIpLb:UILabel!
    
    var isInitialized:Bool = false
    var isStarted:Bool = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //var farIpAddress:String? = ""
        
        initSubviews()
        
        speech = SimpleSpeech()
        
        
        var tapGesture = UITapGestureRecognizer(target:self, action:"handleTapGesture:")
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        
        //左划
        var swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: "handleSwipeGesture:")
        swipeLeftGesture.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipeLeftGesture)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
 
        
    }
    
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        localIpLb.text = "本机ip地址:" + SimpleSpeech.getLocalIp()
        ipAdress.text = SimpleSpeech.getLocalIp()
    }
   
    
    func applicationDidEnterBackground(application: UIApplication) {
        
        
        self.UnInitBtnClicked(nil)
        
        
        
    }
    
    
    
    //布局
    func initSubviews() {
        

        ipAdress = UITextField()
        ipAdress.borderStyle = UITextBorderStyle.RoundedRect
        ipAdress.keyboardType = UIKeyboardType.DecimalPad
        ipAdress.textAlignment = NSTextAlignment.Center
        ipAdress.frame = CGRectMake(20, 50, self.view.frame.size.width - 2*20, 40)
        ipAdress.placeholder = "请输入对方ip地址"
        ipAdress.text = SimpleSpeech.getLocalIp()
        self.view.addSubview(ipAdress)
        
        
        let initBtn = UIButton.buttonWithType(UIButtonType.System) as UIButton
        initBtn.frame = CGRectMake(20, 50 + 60, self.view.frame.size.width - 2*20, 45);
        initBtn.setTitle("初始化", forState: UIControlState.Normal)
        initBtn.addTarget(self, action: "InitBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(initBtn)
        
        
        let unInitBtn = UIButton.buttonWithType(UIButtonType.System) as UIButton
        unInitBtn.frame = CGRectMake(20, 50 + (45 + 10) + 60, self.view.frame.size.width - 2*20, 45);
        unInitBtn.setTitle("反初始化", forState: UIControlState.Normal)
        unInitBtn.addTarget(self, action: "UnInitBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
         self.view.addSubview(unInitBtn)
        
        let startBtn = UIButton.buttonWithType(UIButtonType.System) as UIButton
        startBtn.frame = CGRectMake(20, 50 + (45 + 10)*2 + 40 + 60, self.view.frame.size.width - 2*20, 45);
        startBtn.setTitle("开 始", forState: UIControlState.Normal)
        startBtn.addTarget(self, action: "StartBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(startBtn)
        
        
        let stopBtn = UIButton.buttonWithType(UIButtonType.System) as UIButton
        stopBtn.frame = CGRectMake(20, 50 + (45 + 10)*3 + 40 + 60, self.view.frame.size.width - 2*20, 45);
        stopBtn.setTitle("停 止", forState: UIControlState.Normal)
        stopBtn.addTarget(self, action: "StopBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(stopBtn)
        
        
        localIpLb = UILabel();
        localIpLb.frame = CGRectMake(20, 50 + (45 + 10)*4 + 40 + 60, self.view.frame.size.width - 2*20, 45);
        localIpLb.textAlignment = NSTextAlignment.Center
        localIpLb.text = "本机ip地址:" + SimpleSpeech.getLocalIp()
        self.view.addSubview(localIpLb)
        
        stateLb = UILabel();
        stateLb.frame = CGRectMake(20, 50 + (45 + 10)*5 + 40 + 60, self.view.frame.size.width - 2*20, 45);
        stateLb.textAlignment = NSTextAlignment.Center
        stateLb.text = ">>>状态<<<"
        self.view.addSubview(stateLb)
        
        
    }
    
    
    func handleTapGesture(sender: UITapGestureRecognizer) {
        
        ipAdress.resignFirstResponder()
    }
    
    func handleSwipeGesture(sender: UITapGestureRecognizer) {
        
        ipAdress.resignFirstResponder()
    }
    
    
    func InitBtnClicked(sender:UIButton!) {
        
        if(!isInitialized) {
            
            UIApplication.sharedApplication().idleTimerDisabled = true
            
            speech?.initSpeech(ipAdress.text)
        
            stateLb.text = "已初始化"
            
            isInitialized = !isInitialized
            
            println("initBtnClicked")
        }
        
    }
    
    func UnInitBtnClicked(sender:UIButton!) {
        
        if(isInitialized) {
            
            UIApplication.sharedApplication().idleTimerDisabled = false

            //StopBtnClicked(nil)
            
            speech?.uninitSpeech()
            
            stateLb.text = ""
            
            println("unInitBtnClicked")
            
            isInitialized = false
        }
        
    }
    
    func StartBtnClicked(sender:UIButton!) {
        
        if(isInitialized) {
            
            speech?.start()
        
            println("startBtnClicked")
            
            stateLb.text = "播放中"
            isStarted = true
        }
    }
    
    func StopBtnClicked(sender:UIButton!) {
        
        if(isInitialized) {
            
            speech?.stop()
        
            println("StopBtnClicked")
            
            stateLb.text = "播放停止"
            isStarted = false
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

