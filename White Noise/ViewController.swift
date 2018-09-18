//
//  ViewController.swift
//  White Noise
//
//  Created by David Albers on 4/9/17.
//  Copyright © 2017 David Albers. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
    lazy var player: AVAudioPlayer? = self.makePlayer()                         // Creates player
    var presenter: MainPresenter?
    var timer: Timer?
   
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timerPicker: UIDatePicker!
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var wavesSwitch: UISwitch!
    @IBOutlet weak var fadeSwitch: UISwitch!
    @IBOutlet weak var colorSegmented: UISegmentedControl!
    @IBOutlet weak var mpVolumeViewParentView: UIView!
    
    
    // Sets colors for sound type "colors".
    
    let grey : UIColor = UIColor(red: 201, green: 201, blue: 201)
    let pink : UIColor = UIColor(red: 255, green: 207, blue: 203)
    let brown : UIColor = UIColor(red: 161, green: 136, blue: 127)
    let white : UIColor = UIColor(red: 255, green: 255, blue: 255)

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category.  Error: \(error)")
        }
        timerLabel.text = ""
        timerPicker.setValue(UIColor.white, forKey: "textColor")
        presenter = MainPresenter(viewController: self)
        presenter?.loadSaved()
    
        mpVolumeViewParentView.backgroundColor = UIColor.clear
        let mpVolumeView = MPVolumeView(frame: mpVolumeViewParentView.bounds)
        mpVolumeViewParentView.addSubview(mpVolumeView)
        
    }
    
    @objc func update() {
        presenter?.tick()                                                       // Ticks each second for
    }
    
  
    private func makePlayer() -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: presenter?.getColor().rawValue,
                                  withExtension: "mp3")!                        // Gets the file name based on selection
        let player = try? AVAudioPlayer(contentsOf: url)                        // Attempt to play the file

        player?.numberOfLoops = -1 // Loops infinitely
        return player
    }
    
    public func resetPlayer(restart: Bool) {
        player?.pause()                                                         // Sets player to paused
        player = makePlayer()                                                   // Creates a new player?
        if (restart) {
            player?.play()
        }
    }
    
    public func play() {
        timer?.invalidate()                                                     // Removes any existing timer
        timer = Timer.scheduledTimer(timeInterval: MainPresenter.tickInterval,
                                     target: self,
                                     selector: #selector(self.update),
                                     userInfo: nil,
                                     repeats: true)
        player?.play()                                                          // Starts the audio.
        
        UIApplication.shared.beginReceivingRemoteControlEvents()                // Lets headphones or other accessories control audio
        let commandCenter = MPRemoteCommandCenter.shared()                      // Lets Command Center control audio
        weak var weakSelf = self
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in   // Command Center pause
            weakSelf?.presenter?.pause()
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in   // Command Center play
            weakSelf?.presenter?.play()
            return .success
        }
        presenter?.saveState()
        
        playButton.setImage(UIImage(named: "pause"), for: UIControl.State.normal)
    }
    
    public func setMediaTitle(title: String) {                                  // Sets Command Center title and image
        if let image = UIImage(named: "darkIcon") {
            let artwork = MPMediaItemArtwork
                .init(boundsSize: image.size,
                      requestHandler: { (size) -> UIImage in return image})
            
            let nowPlayingInfo = [MPMediaItemPropertyTitle : title,
                                  MPMediaItemPropertyArtwork : artwork]
                                        as [String : Any]
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    public func pause() {
        timer?.invalidate()                                                     // Stops the timer
        player?.pause()                                                         // Pauses the player
        
        let btnImage = UIImage(named: "play")                                   // Changes the icon to play button
        playButton.setImage(btnImage, for: UIControl.State.normal)               // ??
    }
    
    public func setVolume(volume: Float) {                                      // Sets volume to 0
        player?.setVolume(volume, fadeDuration: 0)                              // Only calls itself??
    }
    
    public func getTimerPickerTime() -> Double {                                // Gets time that was set on picker
       return timerPicker.countDownDuration
    }
    
    public func cancelTimer(timerText: String) {                                // Invoked on cancelling timer
        timerPicker.isEnabled = true                                            // Enables timer picker
        timerButton.setImage(UIImage(named: "add"), for: .normal)               // Replaces trash icon with add icon
        setTimerText(text: timerText)                                           // Sets timer text to blank (via variable)
    }
    
    public func addTimer(timerText: String) {                                   // Invoked on setting timer.
        timerPicker.isEnabled = false                                           // Disables timer picker
        timerButton.setImage(UIImage(named: "delete"), for: .normal)            // Replaces add icon with trash icon
        setTimerText(text: timerText)                                           // Sets timer text to timer time - how?
    }
    
    public func setTimerText(text: String) {
        timerLabel.text = text
    }
    
    public func setColor(color : MainPresenter.NoiseColors) {                   // Changes te colors of each item.
        switch color {
        case .White:
            colorSegmented.selectedSegmentIndex = 0
            colorSegmented.tintColor = white                                    // Selecting item number
            wavesSwitch.onTintColor = grey                                      // Change wavesSwitch color
            fadeSwitch.onTintColor = grey                                       // Changes fadeSwitch color
            break;
        case .Pink:
            colorSegmented.selectedSegmentIndex = 1
            colorSegmented.tintColor = pink
            wavesSwitch.onTintColor = pink
            fadeSwitch.onTintColor = pink
            break;
        case .Brown:
            colorSegmented.selectedSegmentIndex = 2
            colorSegmented.tintColor = brown
            wavesSwitch.onTintColor = brown
            fadeSwitch.onTintColor = brown
            break;
        }
    }
    
    public func setWavesEnabled(enabled : Bool) {                               // Enable waves
        wavesSwitch.setOn(enabled, animated: false)
    }
    
    public func setFadeEnabled(enabled : Bool) {                                // Enable fade
        fadeSwitch.setOn(enabled, animated: false)
    }
    
    public func setTimerPickerTime(time : Double) {                             // Sets timerPicker
        timerPicker.countDownDuration = time
    }
    
    @IBAction func playPausePressed(_ sender: UIButton) {                       // changes interaction color
        presenter?.playPause()
    }

    @IBAction func colorChangedAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            presenter?.changeColor(color: .White)
            break
        case 1:
            presenter?.changeColor(color: .Pink)
            break
        case 2:
            presenter?.changeColor(color: .Brown)
            break
        default:
            break
        }
    }
    
    
    @IBAction func wavesEnabledAction(_ sender: UISwitch) {
        presenter?.enableWavyVolume(enabled: sender.isOn)
    }
    
    @IBAction func fadeEnabledAction(_ sender: UISwitch) {
        presenter?.enableFadeVolume(enabled: sender.isOn)
    }
    
    @IBAction func timerAddedAction(_ sender: UIButton) {
        presenter?.addDeleteTimer()
    }
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
