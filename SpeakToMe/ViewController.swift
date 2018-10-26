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
    
    @IBOutlet weak var theView: UIView!
    
    let width = UIScreen.main.bounds.size.width
    let height = UIScreen.main.bounds.size.height
    
    private let urlSessionGetClientYahoo = URLSessionGetClient()
    private let urlSessionGetClientGoogle = URLSessionGetClient()
    
    //yahoo word
    struct yWord{
        var surface:String="";
        var baseform:String="";
        var pos:String="";
    }
    
    //google word
    struct gWord{
        var surface:String="";
        var baseform:String="";
        var url:String="";
        var r:Int=0;
        var g:Int=0;
        var b:Int=0;
        var color:UIColor=UIColor.black;
    }
    
    //colored word
    struct cWord{
        var surface:String="";
        var range:Range<String.Index>;
        var r:Int=0;
        var g:Int=0;
        var b:Int=0;
        var color:UIColor=UIColor.black;
    }
    
    struct sWord{
        var surface:String="";
        var r:Int=0;
        var g:Int=0;
        var b:Int=0;
        /*
        var h:Int=0;
        var s:Int=0;
        var br:Int=0;
         */
        var color:UIColor=UIColor.black;
    }
    
    private var lastString="";
    private var nowString="";
    private let DISPLAY_STRING_LENGTH=120;
    
    private var yahooWords:[yWord]=[];
    private var googleWords:[gWord]=[];
    private var coloredWords:[cWord]=[];
    private var sendWords:[sWord]=[];
    private let SEND_WORDS_LENGTH=3;
    
    private var timer=Timer();
    
    private var drawView:DrawView=DrawView();
    
    /*
    private var lastResult:String="";
    private var nowResult:String="";
    private var deltaResult:String="";
    private var words:[String]=[];
    */
    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        drawView = DrawView(frame: theView.bounds)
        drawView.backgroundColor = UIColor.white
        theView.addSubview(drawView)
        
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
        coloredWords=[];
        lastString="";
        nowString="";
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.lastString=self.nowString;
                
                self.nowString=result.bestTranscription.formattedString;
                
                if(self.lastString != self.nowString){
                    print("Best:"+self.nowString);
                    
                    //start callback chain
                    self.yahoo(text:self.nowString);
                    
                    /*
                    //https://dev.classmethod.jp/smartphone/iphone/swift-3-how-to-use-gcd-api-1/
                    // キューを生成してサブスレッドで実行
                    DispatchQueue(label: "jp.classmethod.app.queue").async {
                        self.yahoo(text:self.nowString)
                        // メインスレッドで実行
                        DispatchQueue.main.async {
                            //self.display();
                        }
                    }
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
                    
                    var temp=yWord();
                    temp.surface=surface;
                    temp.baseform=baseform;
                    temp.pos=pos;
                    
                    self.yahooWords.append(temp);
                    
                    print("YahooCallBack: NEW WORD:"+surface+":"+baseform+":"+pos);
                    
                    google(surface:surface,baseform:baseform);
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
    private func google(surface:String,baseform:String){
        let queryItems = [URLQueryItem(name: "surface", value: surface),URLQueryItem(name: "baseform", value: baseform)]
        print("google Query:"+surface+":"+baseform);
        urlSessionGetClientGoogle.getWithCallback(url: "https://us-central1-helloworld-8aa1d.cloudfunctions.net/gToD2", queryItems: queryItems,function:googleCallback)
        return;
    }
    
    
    private func googleCallback(resultString:String){
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
                
                var temp=gWord();
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
        
        //sort out colored words for internal use///////////////////////
        coloredWords=[];
        sendWords=[];
        
        for googleWord in googleWords{
            let ranges=nowString.rangesOfOccurances(of:googleWord.surface);
            for range in ranges{
                let temp=cWord(surface:googleWord.surface, range:range,r:googleWord.r,g:googleWord.g,b:googleWord.b,color:googleWord.color);
                coloredWords.append(temp);
            }
        }
        coloredWords.sort(by: {$0.range.lowerBound<$1.range.lowerBound});
        
        if(coloredWords.count==1){
            let temp=coloredWords[coloredWords.count-1];
            let sendWord=sWord(surface:temp.surface,r:temp.r,g:temp.g,b:temp.b,color:temp.color);
            sendWords.append(sendWord);
            print("last word:"+sendWord.surface);
            
            //update screen
            drawView.setColor(c: temp.color);
            //https://www.hackingwithswift.com/example-code/uikit/how-to-force-a-uiview-to-redraw-setneedsdisplay
            drawView.setNeedsDisplay();
        }
        
        if(coloredWords.count>1){
            let tempOne=coloredWords[coloredWords.count-1];
            let tempTwo=coloredWords[coloredWords.count-2];
            
            let sendWordOne=sWord(surface:tempOne.surface,r:tempOne.r,g:tempOne.g,b:tempOne.b,color:tempOne.color);
            sendWords.append(sendWordOne);
            
            let sendWordTwo=sWord(surface:tempTwo.surface,r:tempTwo.r,g:tempTwo.g,b:tempTwo.b,color:tempTwo.color);
            sendWords.append(sendWordTwo);
            print("last word:"+sendWordOne.surface);
            
            //update screen
            drawView.setColor(cOne: tempOne.color,cTwo:tempTwo.color);
            //https://www.hackingwithswift.com/example-code/uikit/how-to-force-a-uiview-to-redraw-setneedsdisplay
            drawView.setNeedsDisplay();
        }
        /////////////////////////////////////////
        
        var displayString:String=nowString;
        
        if(displayString.count>DISPLAY_STRING_LENGTH){
            displayString=String(displayString.suffix(DISPLAY_STRING_LENGTH));
        }
        
        //https://re-engines.com/2017/09/20/swift-3-%E3%83%86%E3%82%AD%E3%82%B9%E3%83%88%E3%81%AE%E8%A3%85%E9%A3%BE%EF%BC%88%E3%83%95%E3%82%A9%E3%83%B3%E3%83%88%E3%83%BB%E6%96%87%E5%AD%97%E3%82%B5%E3%82%A4%E3%82%BA%E3%83%BB%E6%96%87%E5%AD%97/
        
        let attribute = [NSFontAttributeName: UIFont.systemFont(ofSize: 35)]
        let displayMutableString = NSMutableAttributedString(string:displayString,attributes:attribute);
        
        let underLineAttr = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                             NSUnderlineColorAttributeName: UIColor.black] as [String : Any];
        
        //underline yahoo results
        for yahooWord in yahooWords{
            //https://qiita.com/HIRO-NET/items/b9720ccb3c86e85e5872#%E4%BB%BB%E6%84%8F%E3%81%AE%E6%96%87%E5%AD%97%E5%88%97%E3%82%92%E6%A4%9C%E7%B4%A2%E3%81%99%E3%82%8B
            if let range = displayString.range(of:yahooWord.surface){
                //https://stackoverflow.com/questions/27040924/nsrange-from-swift-range
                displayMutableString.addAttributes(underLineAttr, range:NSRange(range,in:displayString))
            }else{
                continue;
            }
        }
        //
        
        //set color on google results: multiple
        for googleWord in googleWords{
            let ranges=displayString.rangesOfOccurances(of:googleWord.surface);
            //let wordLength=googleWord.surface.count;
            let colorAttr=[NSBackgroundColorAttributeName :googleWord.color,]
            for range in ranges{
                displayMutableString.addAttributes(colorAttr, range:NSRange(range,in:displayString))
            }
        }
       
        //self.textView.text = self.nowString;
        self.textView.attributedText = displayMutableString;
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



