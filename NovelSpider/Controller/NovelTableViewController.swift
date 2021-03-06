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
    var novels = [NovelSnapshot]()
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
        if self.novels.count == 0 {
            self.reloadData(limit: 10)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.novels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NovelTableViewCell", for: indexPath) as! NovelTableViewCell
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
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
        cell.sourceLabel.text = "\(novel.source.name!)(\(novel.source.url!))"
        cell.statusLabel.text = "尚未开始阅读"
        if let lastViewChapter = novel.lastViewChapter {
            cell.statusLabel.text = lastViewChapter.title
        }
        if Int(novel.updates)! > 0 {
            cell.showAccesoryBadge(badge: novel.updates)
        } else {
            cell.accessoryView = nil
        }
        cell.cacheProgressView.isHidden = !novel.isCaching && !novel.isUpdating
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !self.novels[indexPath.row].isCaching && !self.novels[indexPath.row].isUpdating && (self.refreshControl == nil || !self.refreshControl!.isRefreshing)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if self.novels[indexPath.row].isUpdating {
            return nil
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cache = UITableViewRowAction(style: .normal, title: "缓存") { (action, indexPath) in
            let novel = self.novels[indexPath.row]
            self.setEditing(false, animated: true)
            novel.isCaching = true
            if let cell = tableView.cellForRow(at: indexPath) as? NovelTableViewCell {
                cell.cacheProgressView.isHidden = false
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let refreshControl = self.refreshControl
                self.refreshControl = nil
                let result = novel.cache { (progress: Float) in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateCacheProgress"), object: nil, userInfo: [
                        "indexPath": indexPath,
                        "progress": progress
                        ])
                }
                _ = (UIApplication.shared.delegate as! AppDelegate).saveContext()
                self.context.refresh(novel.novel, mergeChanges: false)
                DispatchQueue.main.async {
                    if !result {
                        self.alert(title: "错误", message: "章节缓存失败，请检查网络！", okAction: nil)
                    }
                    if let cell = tableView.cellForRow(at: indexPath) as? NovelTableViewCell {
                        cell.cacheProgressView.isHidden = true
                    }
                    novel.isCaching = false
                    self.refreshControl = refreshControl
                }
            }
        }
        cache.backgroundColor = .gray
        let update = UITableViewRowAction(style: .normal, title: "更新") { (action, indexPath) in
            self.setEditing(false, animated: true)
            self.novels[indexPath.row].isUpdating = true
            if let cell = tableView.cellForRow(at: indexPath) as? NovelTableViewCell {
                cell.cacheProgressView.isHidden = false
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let refreshControl = self.refreshControl
                self.refreshControl = nil
                let result = self.novels[indexPath.row].update { (progress: Float) in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateCacheProgress"), object: nil, userInfo: [
                        "indexPath": indexPath,
                        "progress": progress
                        ])
                }
                _ = (UIApplication.shared.delegate as! AppDelegate).saveContext()
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    if !result {
                        self.alert(title: "错误", message: "小说更新失败，请检查网络！", okAction: nil)
                    }
                    if let cell = tableView.cellForRow(at: indexPath) as? NovelTableViewCell {
                        cell.cacheProgressView.isHidden = true
                    }
                    self.novels[indexPath.row].isUpdating = false
                    self.refreshControl = refreshControl
                }
            }
        }
        update.backgroundColor = .orange
        let delete = UITableViewRowAction(style: .destructive, title: "删除") { (action, indexPath) in
            let novel = self.novels[indexPath.row]
            let alert = UIAlertController(title: nil, message: "您确定要删除选中的小说吗", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "删除选中的小说", style: .destructive) { (result) in
                self.setEditing(false, animated: true)
                self.context.delete(novel.novel)
                if let error = (UIApplication.shared.delegate as! AppDelegate).saveContext() {
                    self.alert(title: "错误", message: "发生未知错误，请稍后重试！\n\(error.localizedDescription)") {
                        self.reloadData(limit: 0)
                    }
                    return
                }
                self.novels.remove(at: indexPath.row)
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.endUpdates()
            })
            alert.addAction(UIAlertAction(title: "仅删除缓存", style: .default) { (result) in
                self.setEditing(false, animated: true)
                novel.removeCache()
                _ = (UIApplication.shared.delegate as! AppDelegate).saveContext()
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
            viewController.novelIndex = self.tableView.indexPathForSelectedRow!.row
            viewController.novel = self.novels[viewController.novelIndex].novel
        }
    }
    
    func reloadData(limit: Int) {
        do {
            let fetchRequest: NSFetchRequest<Novel> = Novel.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Novel.order), ascending: true, selector: #selector(NSString.localizedStandardCompare))]
            fetchRequest.fetchLimit = limit
            self.novels.removeAll(keepingCapacity: true)
            var novels = try self.context.fetch(fetchRequest)
            self.novels.append(contentsOf: NovelSnapshot.snapshots(novels: novels))
            self.tableView.reloadData()
            fetchRequest.fetchOffset += novels.count
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    novels = try self.context.fetch(fetchRequest)
                    while novels.count > 0 {
                        self.novels.append(contentsOf: NovelSnapshot.snapshots(novels: novels))
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                        fetchRequest.fetchOffset += novels.count
                        novels = try self.context.fetch(fetchRequest)
                    }
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func refresh() {
        self.tableView.allowsSelection = false
        self.refreshControl!.attributedTitle = NSAttributedString(string: "正在更新: 0/\(self.novels.count)")
        DispatchQueue.global(qos: .userInitiated).async {
            var result = true
            for (index, novel) in self.novels.enumerated() {
                autoreleasepool {
                    if !novel.update(background: nil) {
                        result = false
                    }
                    _ = (UIApplication.shared.delegate as! AppDelegate).saveContext()
                    self.context.refresh(novel.novel, mergeChanges: false)
                    DispatchQueue.main.sync {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        self.refreshControl!.attributedTitle = NSAttributedString(string: "正在更新: \(index + 1)/\(self.novels.count)")
                    }
                }
            }
            DispatchQueue.main.async {
                self.refreshControl!.endRefreshing()
                self.refreshControl!.attributedTitle = nil
                if !result {
                    self.alert(title: "错误", message: "检查更新失败，请检查网络！", okAction: nil)
                }
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
                        self.novels[i].changeOrder(order: "\(i)")
                    }
                    _ = (UIApplication.shared.delegate as! AppDelegate).saveContext()
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
        if let cell = tableView.cellForRow(at: notification.userInfo!["indexPath"] as! IndexPath) as? NovelTableViewCell {
            DispatchQueue.main.async {
                cell.cacheProgressView.progress = notification.userInfo!["progress"] as! Float
            }
        }
    }
}
