/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The primary view controller. The speach-to-text engine is managed an configured here.
*/

import UIKit
import Speech

struct WordColor {
    var word: String = ""
    var color: UIColor
    init() {
        word = ""
        color=UIColor.black
    }
}

public class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    // MARK: Properties
    
    //private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet var textView : UITextView!
    
    @IBOutlet var recordButton : UIButton!
    
    var lastString = ""
    var newString = ""
    var lastColor:UIColor=UIColor.white
    var data : Array<WordColor> = []

    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
        //textView.backgroundColor = UIColor.lightGray;
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
                The callback may not be called on the main thread. Add an
                operation to the main queue to update the record button's state.
            */
            OperationQueue.main.addOperation {
                switch authStatus {
                    case .authorized:
                        self.recordButton.isEnabled = true

                    case .denied:
                        self.recordButton.isEnabled = false
                        self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)

                    case .restricted:
                        self.recordButton.isEnabled = false
                        self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)

                    case .notDetermined:
                        self.recordButton.isEnabled = false
                        self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    
    private func startRecording() throws {

        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                print(result.bestTranscription.segments.forEach {
                    print("--- SEGMENT ---")
                    print("substring            : \($0.substring)")
                    print("timestamp            : \($0.timestamp)")
                    print("duration             : \($0.duration)")
                    print("confidence           : \($0.confidence)")
                    print("alternativeSubstrings: \($0.alternativeSubstrings)")
                    print("")
                })
            }
            
            
            
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                
                let len = Int(bestString.utf16.count);
                
                self.data=[]
                
                var segments: Array<SFTranscriptionSegment>
                segments=result.bestTranscription.segments
                
                for segment in segments{
                    var s: String = ""
                    s=segment.substring
                    print("s:",s)
                    
                    var temp=WordColor()
                    temp.word=s+","
                    temp.color=self.checkForColors(resultString: s)
                    
                    self.data.append(temp)
                    
                    if(self.data.count>10){
                        self.data.remove(at:1)
                    }
                }

                print(len)
                print("best:"+bestString)
               

                
                /*
                if temp.word.contains("して"){
                    self.textView.backgroundColor = self.lastColor
                    self.view.backgroundColor = self.lastColor
                }*/

                
                //self.textView.text=""
                
                //update shown text if transcript is well done.
                //otherwise do nothing
                
                if self.data.count > 0 {
                    let st=NSMutableAttributedString(string:"")
                    for s in self.data {
                        //create color attribute
                        let attribute = [NSForegroundColorAttributeName: s.color, NSFontAttributeName: UIFont.systemFont(ofSize: 35)]
                        //create attributed text
                        let addition = NSMutableAttributedString(string:s.word, attributes: attribute)
                        //add
                        st.append(addition);
                        
                        if s.color != UIColor.darkGray {
                            //self.textView.backgroundColor = s.color
                            //self.view.backgroundColor = s.color
                        }
                    }
                    self.textView.attributedText = st;
                }
                
                //self.textView.text=self.textView.text+bestString
                
                //self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                print("here1")
                self.recordButton.setTitle("I'm keep Recording", for: [])
                print("here2")
     
                try! self.startRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
        //textView.text = "(Go ahead, I'm listening)"
        /*
        for s in self.data {
            self.textView.text = self.textView.text! + s + ", "
        }
 */
    }

    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            print("here1")
            recordButton.isEnabled = true
            recordButton.setTitle("Start Recording", for: [])
            print("here2")
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition not available", for: .disabled)
        }
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func recordButtonTapped() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Stopping", for: .disabled)
        } else {
            try! startRecording()
            recordButton.setTitle("Stop recording", for: [])
        }
    }
    
    func checkForColors(resultString: String)->UIColor {
        if resultString.contains("悲"){
            return UIColor.cyan
        }
        if resultString.contains("楽"){
            return UIColor.magenta
        }
        if resultString.contains("オレンジ"){
            return UIColor.orange
        }
        
        if resultString.contains("黄"){
            return UIColor.yellow
        }
        
        if resultString.contains("緑"){
            return UIColor.green
        }
        
        if resultString.contains("青"){
            return UIColor.blue
        }
        
        if resultString.contains("紫"){
            return UIColor.purple
        }
        
        if resultString.contains("黒"){
            return UIColor.black
        }
        
        if resultString.contains("白"){
            return UIColor.white
        }
        
        if resultString.contains("グレイ"){
            return UIColor.gray
        }
        
        if resultString.contains("赤") || resultString.contains("辛"){
            return UIColor.red
        }
        if resultString.contains("幸せ") || resultString.contains("桃"){
            return UIColor(red:1.0,green:0.2,blue:0.6,alpha:1.0)
        }
        
        return UIColor.darkGray
    }
}

