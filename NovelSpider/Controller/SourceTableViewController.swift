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
        self.reloadData()
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
            let source = self.sources[indexPath.row]
            let alert = UIAlertController(title: "编辑来源", message: nil, preferredStyle: .alert)
            let initTextField: (UITextField) -> Void = { (textField: UITextField) in
                textField.borderStyle = .roundedRect
                textField.frame.size.height = 32
            }
            alert.addTextField { (textField) in
                textField.placeholder = "名称"
                textField.text = source.name
                initTextField(textField)
            }
            alert.addTextField { (textField) in
                textField.placeholder = "URL"
                textField.keyboardType = .URL
                textField.text = source.url
                initTextField(textField)
            }
            alert.addAction(UIAlertAction(title: "确定", style: .default) { (result) in
                let nameTextField = alert.textFields![0]
                let urlTextField = alert.textFields![1]
                guard let name = nameTextField.text, !name.isEmpty, let url = urlTextField.text, !url.isEmpty else {
                    return
                }
                alert.view.endEditing(true)
                DispatchQueue.global(qos: .userInitiated).async {
                    nameTextField.isEnabled = false
                    urlTextField.isEnabled = false
                    source.name = name
                    source.url = url
                    _ = (UIApplication.shared.delegate as! AppDelegate).saveContext()
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            })
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alert, animated: false) {
                for textField in alert.textFields! {
                    if let container = textField.superview, let effectView = container.superview?.subviews.first as? UIVisualEffectView {
                        container.backgroundColor = .clear
                        effectView.removeFromSuperview()
                    }
                }
                alert.view.layoutIfNeeded()
            }
            self.setEditing(false, animated: true)
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
        } else {
            cell.accessoryType = .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeSource"), object: nil, userInfo: [
            "tag": indexPath.row,
            "text": tableView.cellForRow(at: indexPath)!.detailTextLabel!.text!
        ])
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "添加来源", message: nil, preferredStyle: .alert)
        let initTextField: (UITextField) -> Void = { (textField: UITextField) in
            textField.borderStyle = .roundedRect
            textField.frame.size.height = 32
        }
        alert.addTextField { (textField) in
            textField.placeholder = "名称"
            initTextField(textField)
        }
        alert.addTextField { (textField) in
            textField.placeholder = "URL"
            textField.keyboardType = .URL
            initTextField(textField)
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { (result) in
            let nameTextField = alert.textFields![0]
            let urlTextField = alert.textFields![1]
            guard let name = nameTextField.text, !name.isEmpty, let url = urlTextField.text, !url.isEmpty else {
                return
            }
            alert.view.endEditing(true)
            DispatchQueue.global(qos: .userInitiated).async {
                nameTextField.isEnabled = false
                urlTextField.isEnabled = false
                let source = Source(context: self.context)
                source.name = name
                source.url = url
                _ = (UIApplication.shared.delegate as! AppDelegate).saveContext()
                self.sources.append(source)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: false) {
            for textField in alert.textFields! {
                if let container = textField.superview, let effectView = container.superview?.subviews.first as? UIVisualEffectView {
                    container.backgroundColor = .clear
                    effectView.removeFromSuperview()
                }
            }
            alert.view.layoutIfNeeded()
        }
        self.setEditing(false, animated: true)
    }
    
    func reloadData() {
        do {
            self.sources = try self.context.fetch(Source.fetchRequest())
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}
