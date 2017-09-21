//
//  MenuViewController.swift
//  Savour
//
//  Created by Chris Patterson on 9/9/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var webView: UIWebView!
    var request: URLRequest!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.loadRequest(request)

    }
    
    func webViewDidStartLoad(_ : UIWebView) {
        loadingIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(_ : UIWebView) {
        loadingIndicator.stopAnimating()
    }


}
