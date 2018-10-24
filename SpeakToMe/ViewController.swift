/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The primary view controller. The speach-to-text engine is managed an configured here.
*/

import UIKit
import Speech
import Foundation

public class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    // MARK: Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet var textView : UITextView!
    
    @IBOutlet var recordButton : UIButton!
    
    private let urlSessionGetClientYahoo = URLSessionGetClient()
    private let urlSessionGetClientGoogle = URLSessionGetClient()
    
    struct word{
        var surface:String="";
        var baseform:String="";
        var pos:String="";
        var url:String="";
        var isError:Bool=false;
        var r:Int=0;
        var g:Int=0;
        var b:Int=0;
        var color:UIColor=UIColor.black;
    }
    
    private var lastString="";
    private var nowString="";
    
    private var yahooWords:[word]=[];
    private var googleWords:[word]=[];
    
    private var timer=Timer();
    
    /*
    private var lastResult:String="";
    private var nowResult:String="";
    private var deltaResult:String="";
    private var words:[String]=[];
    */
    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
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
        
        //display loop
        timer=Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {(timer)in
            self.display();
            //print("Loop");
        })
        
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
        print("RECOGNITION TASK");
        
        //init
        yahooWords=[];
        googleWords=[];
        lastString="";
        nowString="";
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.lastString=self.nowString;
                
                self.nowString=result.bestTranscription.formattedString;
                
                if(self.lastString != self.nowString){
                    //self.textView.text = self.nowString;
                    
                    //display results
                    //self.display();
                    //
                    print("Best:"+self.nowString);
                    //self.display();
                    
                    //https://dev.classmethod.jp/smartphone/iphone/swift-3-how-to-use-gcd-api-1/
                    // キューを生成してサブスレッドで実行
                    DispatchQueue(label: "jp.classmethod.app.queue").async {
                        self.yahoo(text:self.nowString)
                        //self.google(text:self.nowString);
                        
                        /*
                        for yahooWord in self.yahooWords{
                            self.googleTwo(surface:yahooWord.surface,baseform:yahooWord.baseform);
                        }
 */
                        
                        // メインスレッドで実行
                        DispatchQueue.main.async {
                            //self.display();
                        }
                    }
 
                    
                    /*
                    self.yahoo(text:self.nowString)
                    //self.google(text:self.nowString);
                    
                    for yahooWord in self.yahooWords{
                        self.googleTwo(surface:yahooWord.surface,baseform:yahooWord.baseform);
                    }
                    
                    self.display();
                    */
                    
                }
                
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                //self.recordButton.setTitle("Start Recording", for: [])
                try! self.startRecording();
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
        textView.text = "(Go ahead, I'm listening)ゆっくり話しかけてみましょう。"
    }
    
    private func yahoo(text:String){
        print("Yahoo Query:"+text);
        let queryItems = [URLQueryItem(name: "text", value: text)]
        urlSessionGetClientYahoo.getWithCallback(url: "https://us-central1-helloworld-8aa1d.cloudfunctions.net/yahoo", queryItems: queryItems,function:yahooCallback)
        return;
    }
    
    private func yahooCallback(resultString:String){
        print("Yahoo Callback Result:"+resultString);
        let resultData: Data =  resultString.data(using: String.Encoding.utf8)!
        
        //https://qiita.com/suzuki_y/items/1b64a116ee3c6c9c2805
        //https://qiita.com/nao007_smiley/items/b8df6222cfeb63c842d0
        do{
            let resultJson = try JSONSerialization.jsonObject(with: resultData, options: JSONSerialization.ReadingOptions.allowFragments)
            //var resultsArray=resultJson as! NSArray;
            let resultArray = resultJson as? [[String:Any]]
      
            //Google to dominant color
            for result in resultArray!{
                
                //redunduncy check
                var isAlreadyHere=false;
                for temp in self.yahooWords{
                    let surface:String=result["surface"] as! String;
                    if(temp.surface == surface){
                        isAlreadyHere=true;
                    }
                }
                if(!isAlreadyHere){
                    let surface:String=result["surface"] as! String;
                    let baseform:String=result["baseform"] as! String;
                    let pos:String=result["pos"] as! String;
                    
                    var temp=word();
                    temp.surface=surface;
                    temp.baseform=baseform;
                    temp.pos=pos;
                    
                    self.yahooWords.append(temp);
                    
                    print("YahooCallBack: NEW WORD:"+surface+":"+baseform+":"+pos);
                    //self.display();
                    
                    
                    //google(text:surface);
                    googleTwo(surface:surface,baseform:baseform);
                    /*
                    let queryItems = [URLQueryItem(name: "text", value: result)]
                    print("google Query:"+result);
                    let result=urlSessionGetClientGoogle.getWithCallback(url: "https://us-central1-helloworld-8aa1d.cloudfunctions.net/gToD", queryItems: queryItems,function:googleCallback)
                    */
                }
                //do nothing if the result word is already there
            }
            return;
            
        }catch{
            print(error);
            return;
        }
    }
    
    // MARK: Google and Dominat Color
    private func google(text:String){
        let queryItems = [URLQueryItem(name: "text", value: text)]
        print("google Query:"+text);
        urlSessionGetClientGoogle.getWithCallback(url: "https://us-central1-helloworld-8aa1d.cloudfunctions.net/gToD", queryItems: queryItems,function:googleCallback)
        return;
    }

    
    private func googleCallback(resultString:String){
        print("google Result:"+resultString);
        let resultData: Data =  resultString.data(using: String.Encoding.utf8)!
        do{
            let resultJson = try JSONSerialization.jsonObject(with: resultData, options: JSONSerialization.ReadingOptions.allowFragments)
            
            let resultDict = resultJson as! NSDictionary;
            
            //let surface:String=resultDict["surface"] as! String;
            //let baseform:String=resultDict["baseform"] as! String;
            let text:String=resultDict["text"] as! String;
            
            let url:String=resultDict["url"] as! String;
            /*
            let r:Int=Int(floor(resultDict["r"] as! Float));
            let g:Int=Int(floor(resultDict["g"] as! Float));
            let b:Int=Int(floor(resultDict["b"] as! Float));
             */
            let r:Int=resultDict["r"] as! Int;
            let g:Int=resultDict["g"] as! Int;
            let b:Int=resultDict["b"] as! Int;

            
            print("Google Text:"+text);
            print("Google r:"+String(r)+" g:"+String(g)+" b:"+String(b));
            
            return;
        }catch{
            print(error);
            return;
        }
    }
    
    // MARK: Google and Dominat Color
    private func googleTwo(surface:String,baseform:String){
        let queryItems = [URLQueryItem(name: "surface", value: surface),URLQueryItem(name: "baseform", value: baseform)]
        print("google Query:"+surface+":"+baseform);
        urlSessionGetClientGoogle.getWithCallback(url: "https://us-central1-helloworld-8aa1d.cloudfunctions.net/gToD2", queryItems: queryItems,function:googleCallbackTwo)
        return;
    }
    
    
    private func googleCallbackTwo(resultString:String){
        print("google Result:"+resultString);
        let resultData: Data =  resultString.data(using: String.Encoding.utf8)!
        do{
            let resultJson = try JSONSerialization.jsonObject(with: resultData, options: JSONSerialization.ReadingOptions.allowFragments)
            
            let resultDict = resultJson as! NSDictionary;
            
            let surface:String=resultDict["surface"] as! String;
            let baseform:String=resultDict["baseform"] as! String;
            
            let url:String=resultDict["url"] as! String;
            /*
             let r:Int=Int(floor(resultDict["r"] as! Float));
             let g:Int=Int(floor(resultDict["g"] as! Float));
             let b:Int=Int(floor(resultDict["b"] as! Float));
             */
            let r:Int=resultDict["r"] as! Int;
            let g:Int=resultDict["g"] as! Int;
            let b:Int=resultDict["b"] as! Int;
            
            
            print("Google Text:"+surface+":"+baseform);
            print("Google r:"+String(r)+" g:"+String(g)+" b:"+String(b));
            
            //setColor(text:text,r:r,g:g,b:b);
            //redunduncy check
            var isAlreadyHere=false;
            for temp in self.googleWords{
                if(temp.surface == surface){
                    isAlreadyHere=true;
                }
            }
            
            if(!isAlreadyHere){
                
                var temp=word();
                temp.surface=surface;
                temp.baseform=baseform;
                temp.url=url;
                temp.r=r;
                temp.g=g;
                temp.b=b;
                temp.color=getUIColor(r:r,g:g,b:b);
                self.googleWords.append(temp);
                
                print("GoogleCallBack: NEW WORD:"+surface+":"+String(r)+":"+String(g)+":"+String(b));
                //self.display();
            }
            return;
        }catch{
            print(error);
            return;
        }
    }
    
    
    private func display(){
        if(lastString=="" && nowString==""){
            return;
        }
        //https://re-engines.com/2017/09/20/swift-3-%E3%83%86%E3%82%AD%E3%82%B9%E3%83%88%E3%81%AE%E8%A3%85%E9%A3%BE%EF%BC%88%E3%83%95%E3%82%A9%E3%83%B3%E3%83%88%E3%83%BB%E6%96%87%E5%AD%97%E3%82%B5%E3%82%A4%E3%82%BA%E3%83%BB%E6%96%87%E5%AD%97/
        
        let attribute = [NSFontAttributeName: UIFont.systemFont(ofSize: 35)]
        let displayString = NSMutableAttributedString(string:self.nowString,attributes:attribute);
        
        let underLineAttr = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                             NSUnderlineColorAttributeName: UIColor.black] as [String : Any];
        
        //underline yahoo results
        for yahooWord in yahooWords{
            //https://qiita.com/HIRO-NET/items/b9720ccb3c86e85e5872#%E4%BB%BB%E6%84%8F%E3%81%AE%E6%96%87%E5%AD%97%E5%88%97%E3%82%92%E6%A4%9C%E7%B4%A2%E3%81%99%E3%82%8B
            if let range = self.nowString.range(of:yahooWord.surface){
                //https://stackoverflow.com/questions/27040924/nsrange-from-swift-range
                displayString.addAttributes(underLineAttr, range:NSRange(range,in:self.nowString))
            }else{
                continue;
            }
        }
        //
        
        //set color on google results
        for googleWord in googleWords{
            if let range = self.nowString.range(of:googleWord.surface){
                
                var colorAttr=[NSForegroundColorAttributeName:googleWord.color]
                //https://stackoverflow.com/questions/27040924/nsrange-from-swift-range
                displayString.addAttributes(colorAttr, range:NSRange(range,in:self.nowString))
            }else{
                continue;
            }
        }
       
        
        //self.textView.text = self.nowString;
        self.textView.attributedText = displayString;
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("Start Recording", for: [])
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
            try! self.startRecording()
            recordButton.setTitle("SPEAK!", for: [])
        }
    }
    
    private func getUIColor(r:Int,g:Int,b:Int) -> UIColor{
        let color:UIColor=UIColor(
            red:CGFloat(Float(r)/Float(255.0)),
            green:CGFloat(Float(g)/Float(255.0)),
            blue:CGFloat(Float(b)/Float(255.0)),
            alpha:CGFloat(1.0)
        );
        return color;
    }
        
}



