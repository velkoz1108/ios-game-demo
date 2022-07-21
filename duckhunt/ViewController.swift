//
//  ViewController.swift
//  duckhunt
//
//  Created by Wang, Tao on 2022/7/12.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var barrelImageView: UIImageView!
    @IBOutlet weak var crossHairsImageView: UIImageView!
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet var ducks: [Duck]!
    @IBOutlet weak var ball: UIImageView!
    
    var duckTimer : Timer?
    var gameTimer : Timer?
    var ballTimer : Timer?
    
    var backMusicPlayer: AVAudioPlayer?
    var gunshotPlayer: AVAudioPlayer?
    var duckQuackPlayer: AVAudioPlayer?
    var duckHitPlayer: AVAudioPlayer?
    
    var score:Int = 0{
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    var time:Int = 30{
        didSet{
            timeLabel.text = "Time:".appendingFormat("%02d", time)
            if time == 0{
                gameOver()
            }
        }
    }
    
    
//    lazy var barrelMaxY = self.barrelImageView.frame.maxY
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.backMusicPlayer?.play()
        self.startButton.isHidden = false
        self.ball.isHidden =  true
    }


    @objc func updateDuckLoacation(sender:Timer){
        for duck in ducks {
            if !duck.isDead{
                let oldPosition = duck.frame.origin
                let randomX = arc4random() % 26 + 5
    //            let randomY = arc4random() % 3
                
                var newX: CGFloat
                if oldPosition.x >= UIScreen.main.bounds.maxX{
                    newX = -20
                }else{
                    newX =  oldPosition.x + CGFloat(randomX)
                }
                
                let newPosition = CGPoint(x:newX, y: oldPosition.y )
                duck.frame.origin = newPosition
            }else{
               var newY = duck.frame.origin.y
                if newY >= UIScreen.main.bounds.maxY - duck.frame.size.height {
                    newY = UIScreen.main.bounds.maxY - duck.frame.size.height
                    
                    self.duckHitPlayer?.play()
                    
                    self.perform(#selector(reviveDuck(duck:)),with: duck,afterDelay: 0.0)
                }else{
                    newY += 70
                }
                duck.frame.origin =  CGPoint(x:duck.frame.origin.x, y: newY)
            }
            
        }
    }
    
    @IBAction func tapScreen(_ sender: UITapGestureRecognizer) {
        if time == 0 {
            return
        }
        self.gunshotPlayer?.play()
        
        let touchPosition = sender.location(in: self.view)
        crossHairsImageView.center = touchPosition
        
        let x = touchPosition.x
        let y = touchPosition.y
        
        let disX =  x - UIScreen.main.bounds.maxX / 2
        let disY = UIScreen.main.bounds.maxY - y
        
        barrelImageView.transform = CGAffineTransform(rotationAngle: atan(disX/disY))
        
        
        barrelImageView.layer.position = CGPoint(x: UIScreen.main.bounds.maxX/2, y: UIScreen.main.bounds.maxY)
        
        barrelImageView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.ball.center = CGPoint(x: UIScreen.main.bounds.maxX/2, y:UIScreen.main.bounds.maxY )
        self.ball.isHidden = false
    
        
        collisionDuck(by: touchPosition)
    }
    
    @objc func updateBallPosition(sender:Timer){
        if !ball.isHidden {
            let position = ball.center
            let target = crossHairsImageView.center
            
            var disX = 0.0
            var disY = 0.0
       
            disX = (target.x - UIScreen.main.bounds.maxX/2 ) / 5
            disY = (target.y - UIScreen.main.bounds.maxY) / 5
            
            ball.layer.position = CGPoint(x: position.x + disX, y: position.y + disY)
            
            if position.x + disX < 0 || position.y + disY < 0 {
                self.ball.isHidden = true
            }
        }
    }
    
    func collisionDuck(by touchPoint: CGPoint){
        //击中鸭子的范围
        let hitFrame = CGRect(x: touchPoint.x - 50, y: touchPoint.y - 50, width: 100, height: 100)
        let frightenFrame = CGRect(x: touchPoint.x - 60 , y: touchPoint.y - 60, width: 120, height: 120  )
        
        for duck in ducks {
            if hitFrame.contains(duck.frame) && !duck.isDead {
                duck.image = UIImage(named: "duckdrop")
                duck.isDead = true
                score += 1
                time += 1
            }else if frightenFrame.contains(duck.frame){
                self.duckQuackPlayer?.play()
                
                duck.image = UIImage.animatedImageNamed("duckfrighten_0", duration: 0.7)
                self.perform(#selector(resetDuck(duck:)),with:duck,afterDelay: 2.0)
            }
        }
    
    }
    
    @objc func resetDuck(duck: Duck){
        if !duck.isDead{
            duck.image = UIImage.animatedImageNamed("duckfly_0", duration: 0.7)
        }
    }
    
    @objc func reviveDuck(duck:Duck){
        duck.image = UIImage.animatedImageNamed("duckfly_0", duration: 0.7)
        duck.isDead = false
        let duckSize = duck.frame.size
        let reviveX = -100.0
        let reviceY = 20 + arc4random() % (UInt32(UIScreen.main.bounds.height) - 180)
        duck.frame = CGRect(origin: CGPoint(x: reviveX, y: Double(reviceY)), size: duckSize)
    }
    
    @objc func updateTime(){
        time -= 1
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        gameStart()
        time = 30
        score = 0
    }
    func gameOver(){
        self.startButton.isHidden = false
        self.ball.isHidden = true
        
        self.duckTimer?.invalidate()
        self.duckTimer = nil
        
        self.gameTimer?.invalidate()
        self.gameTimer = nil
        
        self.ballTimer?.invalidate()
        self.ballTimer = nil
    }
    
    func gameStart(){
        self.backMusicPlayer = createAudioPlayer(fileName: "background", loop: true)
        self.duckQuackPlayer = createAudioPlayer(fileName: "duckquack", loop: false)
        self.duckHitPlayer = createAudioPlayer(fileName: "duckgroundhit", loop: false)
        self.gunshotPlayer = createAudioPlayer(fileName: "gunshot", loop: false)
        
        self.ball.isHidden = true
        self.startButton.isHidden = true
        for duck in ducks {
            duck.image  = UIImage.animatedImageNamed("duckfly_0", duration: 0.7)
        }
        
        self.duckTimer =  Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateDuckLoacation(sender:)), userInfo: nil, repeats: true)
        
        self.gameTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        self.ballTimer = Timer.scheduledTimer(timeInterval: 0.08, target: self, selector: #selector(updateBallPosition(sender:)), userInfo: nil, repeats: true)
    }
    
    func createAudioPlayer(fileName: String, loop: Bool) -> AVAudioPlayer? {
        if let path = Bundle.main.path(forResource: fileName, ofType: "mp3"){
            let fileUrl = URL(fileURLWithPath: path)
            let audioPlayer = try? AVAudioPlayer(contentsOf: fileUrl)
            audioPlayer?.numberOfLoops = loop ? -1 : 0
            return audioPlayer
        }else{
            return nil;
        }
        
    }
}

