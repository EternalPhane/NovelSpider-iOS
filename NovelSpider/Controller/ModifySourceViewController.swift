//
//  ModifySourcePopupViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/20.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class ModifySourceViewController: UIViewController {
    var popupTitle: String?
    var sourceTableViewController: SourceTableViewController?
    var source: Source?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.gray.withAlphaComponent(0.75)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismiss as () -> Void))
        tap.cancelsTouchesInView = true
        self.view.addGestureRecognizer(tap)
        (self.childViewControllers.first as! ModifySourcePopupViewController).navigationBar.topItem!.title = self.popupTitle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss() {
        self.dismiss(animated: true) {
            DispatchQueue.main.async {
                do {
                    self.sourceTableViewController!.sources = try self.context.fetch(Source.fetchRequest())
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
                self.sourceTableViewController!.tableView.reloadData()
            }
        }
    }
}
