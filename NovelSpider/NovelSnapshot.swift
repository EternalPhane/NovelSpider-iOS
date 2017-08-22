//
//  NovelSnapshot.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/8/19.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import Foundation
import CoreData

class NovelSnapshot {
    private let id: NSManagedObjectID
    private let context: NSManagedObjectContext
    var name: String
    var source: Source
    var avatar: NSData?
    var order: String
    var updates: String
    var lastViewChapter: Chapter?
    var isCaching = false
    var isUpdating = false
    
    var novel: Novel {
        return self.context.object(with: self.id) as! Novel
    }
    
    init(novel: Novel) {
        self.id = novel.objectID
        self.context = novel.managedObjectContext!
        self.name = novel.name!
        self.source = novel.source!
        self.avatar = novel.avatar
        self.order = novel.order!
        self.updates = novel.updates!
        /*var updates = 0
        for chapter in novel.contents! {
            if (chapter as! Chapter).isNew {
                updates += 1
            }
        }
        self.updates = "\(updates)"
        novel.updates = self.updates*/
        self.lastViewChapter = novel.lastViewChapter
    }
    
    class func snapshots(novels: [Novel]) -> [NovelSnapshot] {
        var snapshots = [NovelSnapshot]()
        for novel in novels {
            snapshots.append(NovelSnapshot(novel: novel))
        }
        return snapshots
    }
    
    func changeOrder(order: String) {
        self.novel.order = order
        self.order = order
    }
    
    func cache(background: @escaping (Float) -> Void) -> Bool {
        return self.novel.cache(background: background)
    }
    
    func update(background: ((Float) -> Void)?) -> Bool {
        let result = self.novel.update(background: background)
        self.updates = self.novel.updates!
        return result
    }
    
    func removeCache() {
        self.novel.removeCache()
    }
}
