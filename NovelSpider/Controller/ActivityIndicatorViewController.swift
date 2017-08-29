//
//  ActivityIndicatorViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/5/14.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class ActivityIndicatorViewController: UIViewController {
    @IBOutlet weak var loadingView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.gray.withAlphaComponent(0.75)
        self.loadingView.layer.cornerRadius = 10
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
