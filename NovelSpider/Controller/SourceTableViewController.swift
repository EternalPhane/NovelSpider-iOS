//
//  SourceTableViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/18.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class SourceTableViewController: UITableViewController {
    var sources = [Source]()
    var selectedRow = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            self.sources = try self.context.fetch(Source.fetchRequest())
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sources.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SourceTableViewCell", for: indexPath) as! SourceTableViewCell
        let source = self.sources[indexPath.row]
        cell.nameLabel.text = source.name != nil ? source.name! : source.url!
        cell.urlLabel.text = source.url
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let edit = UITableViewRowAction(style: .normal, title: "编辑") { (action, indexPath) in
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ModifySourcePopupViewController") as! ModifySourceViewController
            viewController.sourceTableViewController = self
            viewController.popupTitle = "编辑来源"
            viewController.source = self.sources[indexPath.row]
            self.present(viewController, animated: true, completion: nil)
        }
        edit.backgroundColor = .gray
        let delete = UITableViewRowAction(style: .default, title: "删除") { (action, indexPath) in
            let source = self.sources[indexPath.row]
            guard (try? source.validateForDelete()) != nil else {
                self.alert(title: "错误", message: "\"\(source.name!)\"被一本或多本小说引用！", okAction: nil)
                return
            }
            self.context.delete(source)
            _ = (UIApplication.shared.delegate as! AppDelegate).saveContext()
            self.sources.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
        delete.backgroundColor = .red
        return [delete, edit]
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.selectedRow {
            cell.accessoryType = .checkmark
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeSource"), object: nil, userInfo: [
            "tag": indexPath.row,
            "text": tableView.cellForRow(at: indexPath)!.detailTextLabel!.text!
        ])
        self.navigationController!.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ModifySourceViewController {
            viewController.sourceTableViewController = self
            viewController.popupTitle = "添加来源"
        }
    }
}
