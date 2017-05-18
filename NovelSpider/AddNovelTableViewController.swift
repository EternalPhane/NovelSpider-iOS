//
//  AddNovelTableViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/18.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class AddNovelTableViewController: UITableViewController {
    @IBOutlet weak var nameTableViewCell: UITableViewCell!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var sourceTableViewCell: UITableViewCell!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var searchEngineTableViewCell: UITableViewCell!
    @IBOutlet weak var searchEngineLabel: UILabel!
    @IBOutlet weak var depthTableViewCell: UITableViewCell!
    @IBOutlet weak var depthTextField: UITextField!
    var novels: [Novel]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(changeSource), name: NSNotification.Name(rawValue: "changeSource"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeSearchEngine), name: NSNotification.Name(rawValue: "changeSearchEngine"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? SourceTableViewController {
            viewController.selectedRow = sourceLabel.tag
        } else if let viewController = segue.destination as? SearchEngineTableViewController {
            viewController.selectedRow = searchEngineLabel.tag
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        self.setEnabled(false)
        self.showActivityIndicator()
        guard let name = self.nameTextField.text, !name.isEmpty, let sources:[Source] = try? self.context.fetch(Source.fetchRequest()), let source = (self.sourceLabel.tag >= 0 && sources.count > self.sourceLabel.tag) ? sources[self.sourceLabel.tag] : nil, let searchEngine = self.searchEngineLabel.text, searchEngine != "", let depth = Int(self.depthTextField.text ?? ""), depth > 0 else {
            self.dismissActivityIndicator() {
                self.setEnabled(true)
            }
            return
        }
        DispatchQueue.global().async {
            guard let contentsUrl = SimpleSpider.getContentsUrl(name: name, source: source.url!, searchEngine: searchEngine, maxDepth: depth), let contents = SimpleSpider.getContents(url: contentsUrl) else {
                self.setEnabled(true)
                self.dismissActivityIndicator(completion: nil)
                return
            }
            let avatar = SimpleSpider.getAvatar(name: name)
            let novel = Novel(context: self.context)
            novel.name = name
            novel.source = source
            novel.contentsUrl = contentsUrl
            novel.avatar = avatar
            for obj in contents {
                let chapter = Chapter(context: self.context)
                chapter.title = obj.title
                chapter.url = obj.url
                chapter.isNew = false
                novel.addChapter(chapter: chapter)
            }
            novel.order = "0"
            for novel in self.novels! {
                novel.order = "\(Int(novel.order!)! + 1)"
            }
            self.novels!.insert(novel, at: 0)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            DispatchQueue.main.async {
                self.dismissActivityIndicator() {
                    self.navigationController!.popViewController(animated: true)
                }
            }
        }
    }
    
    func setEnabled(_ isEnabled: Bool) {
        self.nameTextField.isEnabled = isEnabled
        self.depthTextField.isEnabled = isEnabled
        self.sourceTableViewCell.isUserInteractionEnabled = isEnabled
        self.searchEngineTableViewCell.isUserInteractionEnabled = isEnabled
        self.navigationController!.navigationBar.isUserInteractionEnabled = isEnabled
    }
    
    func changeSource(notification: Notification) {
        self.sourceLabel.tag = notification.userInfo!["tag"] as! Int
        self.sourceLabel.text = (notification.userInfo!["text"] as! String)
    }
    
    func changeSearchEngine(notification: Notification) {
        self.searchEngineLabel.tag = notification.userInfo!["tag"] as! Int
        self.searchEngineLabel.text = (notification.userInfo!["text"] as! String)
    }
}
