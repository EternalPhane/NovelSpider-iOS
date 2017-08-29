//
//  LabeledActivityIndicatorViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/5/14.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class LabeledActivityIndicatorViewController: UIViewController {
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.gray.withAlphaComponent(0.75)
        self.loadingView.layer.cornerRadius = 10
        NotificationCenter.default.addObserver(self, selector: #selector(setText), name: NSNotification.Name(rawValue: "setLabelText"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setText(notification: Notification) {
        DispatchQueue.main.sync {
            self.infoLabel.text = (notification.userInfo!["text"] as! String)
        }
    }
}
