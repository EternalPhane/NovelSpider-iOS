//
//  ContentsTableViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/22.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class ContentsTableViewController: UITableViewController {
    var novel: Novel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        NotificationCenter.default.addObserver(self, selector: #selector(changeChapter), name: NSNotification.Name(rawValue: "changeChapter"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.novel.contents!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContentsTableViewCell", for: indexPath) as! ContentsTableViewCell
        let chapter = self.novel.contents![indexPath.row] as! Chapter
        cell.titleLabel.text = chapter.title
        if chapter.content != nil {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "selectChapter"), object: nil, userInfo: ["index": indexPath.row])
    }
    
    func changeChapter(notification: Notification) {
        self.tableView.selectRow(at: IndexPath(row: notification.userInfo!["index"] as! Int, section: 0), animated: false, scrollPosition: .middle)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
