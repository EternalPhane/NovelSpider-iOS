//
//  NovelTableViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/17.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit
import CoreData

class NovelTableViewController: UITableViewController {
    var novels = [Novel]()
    var cellSnapshot: UIView?
    var cellIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl!.addTarget(self, action: #selector(refresh), for: .valueChanged)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(sender:)))
        self.tableView.addGestureRecognizer(longPress)
        NotificationCenter.default.addObserver(self, selector: #selector(updateProgress), name: NSNotification.Name(rawValue: "updateCacheProgress"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return novels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NovelTableViewCell", for: indexPath) as! NovelTableViewCell
        if cell.tag == 1 {
            cell.accessoryView = nil
            cell.tag = 0
        }
        let novel = self.novels[indexPath.row]
        cell.avatarImageView.image = nil
        if let avatar = novel.avatar {
            cell.avatarImageView.image = UIImage(data: avatar as Data)
        }
        cell.nameLabel.text = novel.name
        cell.sourceLabel.text = "\(novel.source!.name!)(\(novel.source!.url!))"
        cell.statusLabel.text = "尚未开始阅读"
        if let lastViewChapter = novel.lastViewChapter {
            cell.statusLabel.text = lastViewChapter.title
        }
        if let updates = novel.updates, updates != "0" {
            cell.showAccesoryBadge(badge: updates)
        } else {
            cell.accessoryView = nil
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cell = tableView.cellForRow(at: indexPath) as! NovelTableViewCell
        let handler = { (action: UITableViewRowAction, indexPath: IndexPath) in
            self.setEditing(false, animated: true)
            guard cell.cacheProgressView.isHidden != false else {
                return
            }
            cell.cacheProgressView.isHidden = false
            DispatchQueue.global().async {
                let refreshControl = self.refreshControl
                self.refreshControl = nil
                let result = self.novels[indexPath.row].cache(update: action.title == "更新缓存") { (progress: Float) in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateCacheProgress"), object: nil, userInfo: [
                        "cell": cell,
                        "progress": progress
                    ])
                }
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                DispatchQueue.main.async {
                    if !result {
                        self.alert(title: "错误", message: "章节缓存失败，请检查网络！", okAction: nil)
                    }
                    cell.cacheProgressView.isHidden = true
                    self.refreshControl = refreshControl
                }
            }
        }
        let cache = UITableViewRowAction(style: .normal, title: "缓存", handler: handler)
        cache.backgroundColor = .gray
        let update = UITableViewRowAction(style: .normal, title: "更新缓存", handler: handler)
        update.backgroundColor = .orange
        let delete = UITableViewRowAction(style: .destructive, title: "删除") { (action, indexPath) in
            let novel = self.novels[indexPath.row]
            let alert = UIAlertController(title: nil, message: "您确定要删除选中的小说吗", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "删除选中的小说", style: .destructive) { (result) in
                self.setEditing(false, animated: true)
                self.context.delete(novel)
                if let error = (UIApplication.shared.delegate as! AppDelegate).saveContext() {
                    self.alert(title: "错误", message: "发生未知错误，请稍后重试！\n\(error.localizedDescription)") {
                        self.reloadData()
                    }
                    return
                }
                self.novels.remove(at: indexPath.row)
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            })
            alert.addAction(UIAlertAction(title: "仅删除缓存", style: .default) { (result) in
                self.setEditing(false, animated: true)
                novel.removeCache()
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            })
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { (result) in
                self.setEditing(false, animated: true)
            })
            self.present(alert, animated: true, completion: nil)
        }
        delete.backgroundColor = .red
        return [delete, update, cache]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AddNovelTableViewController {
            viewController.novels = self.novels
        } else if let viewController = segue.destination as? ReaderViewController {
            viewController.novel = self.novels[self.tableView.indexPathForSelectedRow!.row]
            viewController.novel.updates = "0"
        }
    }
    
    func reloadData() {
        do {
            let fetchRequest: NSFetchRequest<Novel> = Novel.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Novel.order), ascending: true)]
            self.novels = try self.context.fetch(fetchRequest)
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        self.tableView.reloadData()
    }
    
    func refresh() {
        self.tableView.allowsSelection = false
        DispatchQueue.global().async {
            var result = false
            for novel in self.novels {
                result = novel.update()
                guard result else {
                    break
                }
            }
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            DispatchQueue.main.async {
                self.refreshControl!.endRefreshing()
                if !result {
                    self.alert(title: "错误", message: "检查更新失败，请检查网络！") {
                        self.refreshControl!.endRefreshing()
                        self.tableView.reloadData()
                    }
                }
                self.tableView.reloadData()
                self.tableView.allowsSelection = true
            }
        }
    }
    
    func longPressAction(sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        switch sender.state {
        case .began:
            guard indexPath != nil else {
                return
            }
            self.cellIndexPath = indexPath
            let cell = self.tableView.cellForRow(at: indexPath!)!
            self.cellSnapshot = getCellSnapshot(cell: cell)
            self.cellSnapshot!.center = cell.center
            self.cellSnapshot!.alpha = 0
            self.tableView.addSubview(self.cellSnapshot!)
            UIView.animate(withDuration: 0.25, animations: {
                self.cellSnapshot!.center.y = location.y
                self.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.cellSnapshot!.alpha = 0.9
                cell.alpha = 0
            }, completion: { (finished) in
                if finished {
                    cell.isHidden = true
                }
            })
            break
        case .changed:
            guard self.cellSnapshot != nil, indexPath != nil else {
                return
            }
            self.cellSnapshot!.center.y = location.y
            let screenLocation = sender.location(in: self.tableView.superview)
            if screenLocation.y < 100 && indexPath!.row > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: indexPath!.row - 1, section: 0), at: .top, animated: true)
            } else if screenLocation.y > self.view.superview!.bounds.height - 100 && indexPath!.row < self.novels.count - 1 {
                self.tableView.scrollToRow(at: IndexPath(row: indexPath!.row + 1, section: 0), at: .bottom, animated: true)
            }
            if indexPath != self.cellIndexPath, indexPath!.row < self.novels.count {
                swap(&self.novels[self.cellIndexPath!.row], &self.novels[indexPath!.row])
                self.tableView.beginUpdates()
                self.tableView.moveRow(at: self.cellIndexPath!, to: indexPath!)
                self.tableView.endUpdates()
                self.cellIndexPath = indexPath
            }
            break
        default:
            guard self.cellSnapshot != nil, indexPath != nil else {
                return
            }
            
            let cell = self.tableView.cellForRow(at: self.cellIndexPath!)!
            cell.isHidden = false
            cell.alpha = 0
            UIView.animate(withDuration: 0.25, animations: {
                self.cellSnapshot!.center = cell.center
                self.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.cellSnapshot!.alpha = 0
                cell.alpha = 1
            }, completion: { (finished) in
                if finished {
                    self.cellIndexPath = nil
                    self.cellSnapshot!.removeFromSuperview()
                    self.cellSnapshot = nil
                    for i in 0..<self.novels.count {
                        self.novels[i].order = "\(i)"
                    }
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                }
            })
            break
        }
    }
    
    func getCellSnapshot(cell: UITableViewCell) -> UIView {
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, 0)
        cell.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let cellSnapshot = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5, height: 0)
        cellSnapshot.layer.shadowRadius = 5
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
    
    func updateProgress(notification: Notification) {
        DispatchQueue.main.async {
            (notification.userInfo!["cell"] as! NovelTableViewCell).cacheProgressView.progress = notification.userInfo!["progress"] as! Float
        }
    }
}