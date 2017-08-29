//
//  modifySourceViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/20.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit
import CoreData

class ModifySourcePopupViewController: UIViewController {
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var urlTextField: UITextField!
    var modifySourceViewController: ModifySourceViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.cornerRadius = 5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.modifySourceViewController = (self.parent as! ModifySourceViewController)
        if self.modifySourceViewController!.popupTitle == "编辑来源" {
            self.nameTextField.text = self.modifySourceViewController!.source!.name
            self.urlTextField.text = self.modifySourceViewController!.source!.url
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        guard let name = self.nameTextField.text, !name.isEmpty, let url = self.urlTextField.text, !url.isEmpty else {
            return
        }
        self.view.endEditing(true)
        self.showActivityIndicator()
        DispatchQueue.global().async {
            self.nameTextField.isEnabled = false
            self.urlTextField.isEnabled = false
            var source: Source
            if self.modifySourceViewController!.popupTitle == "添加来源" {
                source = Source(context: self.context)
            } else {
                source = self.modifySourceViewController!.source!
            }
            source.name = name
            source.url = url
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            DispatchQueue.main.async {
                self.dismissActivityIndicator() {
                    self.modifySourceViewController!.dismiss()
                }
            }
        }
    }
}
