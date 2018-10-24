//
//  URLSessionGetClient.swift
//  SpeakToMe
//
//  Created by Noriyuki Fujimura on 2018/10/24.
//  Copyright © 2018 Henry Mason. All rights reserved.
//

import Foundation

//https://qiita.com/yutailang0119/items/ab400cb7158295a9c171
class URLSessionGetClient {
    var result:String="";
    
    func get(url urlString: String, queryItems: [URLQueryItem]? = nil)->String {
        var compnents = URLComponents(string: urlString)
        compnents?.queryItems = queryItems
        let url = compnents?.url
        
        //self.result="";
        
        for temp in queryItems!{
            print("URLSessionGetClient:Query"+temp.name+":"+temp.value!);
        }
        
        let task = URLSession.shared.dataTask(with: url!){ data, response, error in
            if let data = data, let response = response {
                //print(response);
                self.result=String(data: data, encoding: String.Encoding.utf8) ?? "";
                print("URLSessionGetClient:Result"+self.result)
                /*
                 do {
                 let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                 print(json)
                 } catch {
                 print("Serialize Error")
                 }
                 */
                
            } else {
                print(error ?? "Error")
            }
        }
        
        task.resume()
        //print("Get3:"+self.result)
        return self.result;
    }
    
    func getWithCallback(url urlString: String, queryItems: [URLQueryItem]? = nil,function:@escaping (String)->Void) {
        var compnents = URLComponents(string: urlString)
        compnents?.queryItems = queryItems
        let url = compnents?.url
        
        //self.result="";
        
        for temp in queryItems!{
            //print("URLSessionGetClient:Query"+temp.name+":"+temp.value!);
        }
        
        let task = URLSession.shared.dataTask(with: url!){ data, response, error in
            if let data = data, let response = response {
                //print(response);
                self.result=String(data: data, encoding: String.Encoding.utf8) ?? "";
                //print("URLSessionGetClient:Result"+self.result)
                function(self.result);
                /*
                 do {
                 let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                 print(json)
                 } catch {
                 print("Serialize Error")
                 }
                 */
                
            } else {
                print(error ?? "Error")
            }
        }
        task.resume()
    }
    
}

