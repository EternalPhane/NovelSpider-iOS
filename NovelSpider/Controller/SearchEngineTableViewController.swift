//
//  SearchEngineTableViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/18.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class SearchEngineTableViewController: UITableViewController {
    var selectedRow = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.selectedRow {
            cell.accessoryType = .checkmark
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeSearchEngine"), object: nil, userInfo: [
            "tag": indexPath.row,
            "text": tableView.cellForRow(at: indexPath)!.textLabel!.text!
        ])
        self.navigationController!.popViewController(animated: true)
    }
}
