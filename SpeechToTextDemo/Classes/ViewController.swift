//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by Nirzar Gandhi on 24/01/24.
//

import Speech
import UIKit

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var speechToTextBtn: UIButton!
    @IBOutlet weak var textlbl: UILabel!
    
    
    // MARK: - Properties
    fileprivate let audioEngine = AVAudioEngine()
    fileprivate let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    fileprivate lazy var request = SFSpeechAudioBufferRecognitionRequest()
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    
    fileprivate lazy var isRecording = false
    
    fileprivate var timer : Timer?
    
    
    // MARK: -
    // MARK: - View init Methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


// MARK: - Call Back
extension ViewController {
    
    fileprivate func checkMicPermission() {
        
        switch AVAudioSession.sharedInstance().recordPermission {
            
        case .granted:
            self.checkSpeechPermission()
            
        case .denied:
            DispatchQueue.main.async {
                self.sendAlert(title: "Denied", message: "User denied access to microphone", isNoPermission: true)
            }
            
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    self.checkSpeechPermission()
                } else {
                }
            })
            
        default:
            break
        }
    }
    
    fileprivate func checkSpeechPermission() {
        
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            OperationQueue.main.addOperation {
                
                switch authStatus {
                    
                case .authorized:
                    self.startTimer()
                    
                case .denied:
                    self.sendAlert(title: "Denied", message: "User denied access to speech recognition", isNoPermission: true)
                    
                case .restricted:
                    self.sendAlert(title: "Restricted", message: "Speech recognition restricted on this device", isNoPermission: true)
                    
                case .notDetermined:
                    self.sendAlert(title: "Not Determined", message: "Speech recognition not yet authorized", isNoPermission: true)
                    
                @unknown default:
                    return
                }
            }
        }
    }
    
    fileprivate func startTimer() {
        
        self.textlbl.text = "I am Listening..."
        
        self.timer?.invalidate()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] timer in
            
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.isRecording {
                self.stopTimer()
            } else {
                self.isRecording = true
                
                self.recordAndRecognizeSpeech()
            }
        }
        
        self.timer?.fire()
    }
    
    fileprivate func stopTimer() {
        
        if self.textlbl.text == "I am Listening..." {
            self.textlbl.text = "Hi, I’m Listening. Try saying..."
        }
        
        self.isRecording = false
        
        self.cancelRecording()
        
        self.timer?.invalidate()
        self.timer = nil
    }
    
    fileprivate func recordAndRecognizeSpeech() {
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        self.audioEngine.prepare()
        
        do {
            try self.audioEngine.start()
        } catch {
            self.sendAlert(title: "Speech Recognizer Error", message: "There has been an audio engine error.")
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not supported for your current locale.")
            return
        }
        
        if !myRecognizer.isAvailable {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not currently available. Check back at a later time.")
            return
        }
        
        self.speechRecognizer?.defaultTaskHint = .dictation
        
        self.recognitionTask = SFSpeechRecognizer()?.recognitionTask(with: request, resultHandler: { result, error in
            
            if let result = result {
                
                let resultStr = result.bestTranscription.formattedString
                
                if resultStr.count > 3 && result.isFinal {
                    self.textlbl.text = resultStr
                    
                    self.stopTimer()
                }
                
            } else if let error = error {
                
                self.sendAlert(title: "Speech Recognizer Error", message: "There has been a speech recognition error: \(error)")
                
                self.stopTimer()
            }
        })
    }
    
    fileprivate func cancelRecording() {
        
        self.recognitionTask?.finish()
        self.recognitionTask = nil
        
        self.request = SFSpeechAudioBufferRecognitionRequest()
        self.audioEngine.stop()
        self.audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    fileprivate func sendAlert(title: String, message: String, isNoPermission: Bool = false) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        if isNoPermission {
            
            alert.addAction(UIAlertAction(title: "Setting", style: .cancel) { _ in
                
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, options: [:])
                }
            })
            
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}


// MARK: - Button Touch & Action
extension ViewController {
    
    @IBAction func speechToTextBtnTouch(_ sender: Any) {
        
        if self.isRecording {
            self.stopTimer()
        } else {
            self.checkSpeechPermission()
        }
    }
}
