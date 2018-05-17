//
//  ViewController.swift
//  OneDrive
//
//  Created by students on 03/03/2018.
//  Copyright © 2018 students. All rights reserved.
//

import UIKit
import WebKit
class ViewController: UIViewController , WKUIDelegate, WKNavigationDelegate{
    
    var myCode: String?
    var myToken: String?

    @IBOutlet weak var datview: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        let link =  "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=a74d3beb-bc2a-4ba5-b650-fda92574023a&scope=files.read&response_type=code&redirect_uri=msala74d3beb-bc2a-4ba5-b650-fda92574023a://auth"
        

        let url = URL(string:link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
      
        let req = URLRequest(url: url!)
        datview.navigationDelegate = self as WKNavigationDelegate;
        datview.load(req)
        
}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
}
    
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
}
    

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if (myCode != nil) {
       // POST req
        let url = URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let clientID = "a74d3beb-bc2a-4ba5-b650-fda92574023a"
              
        let postString = "client_id="+clientID+"&redirect_uri=msala74d3beb-bc2a-4ba5-b650-fda92574023a://auth&code=\(myCode!)&grant_type=authorization_code"
            request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
 //           print("responseString = \(responseString)")
            self.webView2(responseString: responseString!)
            let dict = self.convertToDictionary(text: responseString!)
            let myToken =  dict!["access_token"] as! String
            self.getDrive(token: myToken)
        }
        task.resume()
        }
}
    
    func getDrive(token: String){
        // GET req
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/drives/51420aa3cd61f800/root/children")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print(responseString)
       
            DispatchQueue.main.async { [unowned self] in
                    self.datview.loadHTMLString(responseString!, baseURL: nil)
            }
            
        }
               task.resume()
}
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let fullString = navigationAction.request.url?.absoluteString
        if fullString?.range(of:"code=") != nil {
            let fullStringArray = fullString?.components(separatedBy: "=")

            myCode = fullStringArray![1]
            print(myCode!)
        }

        decisionHandler(WKNavigationActionPolicy.allow)
}
    
    
    func webView2(responseString: String) {

        let fullStringArray = responseString.components(separatedBy: ",")
        print(fullStringArray.last!)

}

}

