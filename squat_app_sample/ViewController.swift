//
//  ViewController.swift
//  squat_app_sample
//
//  Created by Shinya Hirai on 2015/11/24.
//  Copyright (c) 2015年 Shinya Hirai. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var countLabel: UILabel!
    
    @IBOutlet weak var startAndStopBtn: UIButton!
    
    @IBOutlet weak var squatsImageView: UIImageView!
    
    let motionManager = CMMotionManager()
    
    var isCounting:Bool = false
    var isSitting:Bool = false
    var isDecelerationStarted:Bool = false
    var count:Int = 0
    var timer:NSTimer = NSTimer()
    
    // 減速しているとみなすユーザー加速度の大きさの閾値
    let kUserAccelerationThreshold:Double = 0.15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        squatsImageView.image = UIImage(named: "Squats_up.png")
        
        changeViewState()
        
        self.motionManager.accelerometerUpdateInterval = 0.1
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changeViewState() {
        
        squatsImageView.image = UIImage(named: "Squats_up.png")
        
        if (isCounting) {
            
            startAndStopBtn.setTitle("ストップ", forState: .Normal)
            
        } else {
            
            startAndStopBtn.setTitle("スタート", forState: .Normal)
            countLabel.text = "0回" // String(count)
            
        }
    }
    
    func startCounting() {
        
        // モーションデータ更新時のハンドラを作成
        let deviceHandler:CMDeviceMotionHandler = {(motion:
            CMDeviceMotion!, error:NSError!) -> Void in
            
            // ユーザー加速度の重力方向の大きさを算出
            var magnitude:Double = self.gravityDirectionMagnitudeForMotion(motion)
            
            // 算出したユーザー加速度の重力方向の大きさからスクワットの動きを判定
            self.validateGravityDirectionMagnitude(magnitude)
        }
        
        motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: deviceHandler)
        
        count = 0
        isCounting = true
        changeViewState()
        
        isSitting = true
        
    }
    
    func stopCounting() {
        motionManager.stopDeviceMotionUpdates()
        
        if (timer.valid) {
            timer.invalidate()
        }
        
        isCounting = false
        changeViewState()
    }
    
    func updateViewAnimated(animated:Bool) {
        // カウント回数ラベルの更新
        countLabel.text = String(count) + "回"
        
        // 矢印イメージの更新
        if (animated) {
            squatsImageView.image = UIImage(named: "Squats_up.png")
        } else {
            squatsImageView.image = UIImage(named: "Squats_down.png")
        }

    }
    
    

    @IBAction func startAndStopBtn(sender: AnyObject) {
        
        // デバイスのハードウェアチェック
        if (!motionManager.deviceMotionAvailable) {
            println("DeviceMotion is not available")
            return
        }
        
        if (isCounting) {
            // カウント終了
            stopCounting()
        } else {
            // カウント開始
            startCounting()
        }
        
    }
    
    func gravityDirectionMagnitudeForMotion(motion:CMDeviceMotion) -> Double {
        // 重力加速度データ
        var gravity = motion.gravity
        println("=================================")
//        println(gravity.x)
//        println(gravity.y)
//        println(gravity.z)
//        
//        println("<<<<<<<<")
        
        // ユーザー加速度
        var user = motion.userAcceleration
//        println(user.x)
//        println(user.y)
//        println(user.z)
        
        // ユーザー加速度の大きさを算出
        var magnitude = sqrt(pow(user.x, 2) + pow(user.y, 2) + pow(user.z, 2))
//        println("magnitude = \(magnitude)")
        
        // ユーザー加速度のベクトルと重力加速度のベクトルのなす角θのcosθを算出
        var cosT = (user.x * gravity.x + user.y * gravity.y + user.z * gravity.z) /
            sqrt((pow(user.x, 2) + pow(user.y, 2) + pow(user.z, 2)) *
                (pow(gravity.x, 2) + pow(gravity.y, 2) + pow(gravity.z, 2)))
        
        
        // ユーザー加速度の大きさにcosθを乗算してユーザー加速度の重力方向における大きさを算出し、小数点第3位で丸める
        var gravityDirectionMagnitude = round(magnitude * cosT * 100) / 100
        
        // この値が一番上で定義されたkUserAccelerationThreshold定数の値0.15より
        // 大きいか小さいかを0.2秒ごとにタイマーで判定しスクワットの処理を実現している
        println("gravityDirectionMagnitude = \(gravityDirectionMagnitude)")
        
        return gravityDirectionMagnitude
    }
    
    func validateGravityDirectionMagnitude(magnitude:Double) {
        
        if (timer.valid) {
            
            // 立ち判定もしくは座り判定中の場合
            if ((!isSitting && isDecelerationStarted && magnitude > -kUserAccelerationThreshold) ||
                (isSitting && isDecelerationStarted && magnitude < kUserAccelerationThreshold)) {
                
                // ユーザー加速度の重力方向における大きさが閾値を下回る場合、判定をキャンセル
                timer.invalidate()
//                timer = nil
                println("timer is canceled.")
            }
            
        } else {
            
            if (!isSitting && magnitude < -kUserAccelerationThreshold) {
                // 立ちフェーズかつユーザー加速度の重力方向における大きさが閾値を上回る場合、立ち判定スタート
                // 一定時間閾値を上回っていた場合に、立ち判定成立
                timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: Selector("timerHandler:"), userInfo: nil, repeats: false)
                
                isDecelerationStarted = true
                println("standing timer start.")
                
            } else if (isSitting && magnitude > kUserAccelerationThreshold) {
                // 座りフェーズかつユーザー加速度の重力方向における大きさが閾値を上回る場合、座り判定スタート
                // 一定時間閾値を上回っていた場合に、座り判定成立
                timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: Selector("timerHandler:"), userInfo: nil, repeats: false)
                
                isDecelerationStarted = true
                println("sitting timer start.")
            }
        }

    }
    
    func timerHandler(aTimer:NSTimer) {
        println("timer completed")
        if (isSitting) {
            // 座り判定成立、立ちフェーズへ
            isSitting = false
            updateViewAnimated(false)
            println("switch to standing.")
        } else {
            // 立ち判定成立、座りフェーズへ
            isSitting = true
            count++
            updateViewAnimated(true)
            println("switch to sitting.")

        }
        
        isDecelerationStarted = false
//        timer = nil
    }
    
}

