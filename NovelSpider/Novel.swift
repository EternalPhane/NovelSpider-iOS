//
//  Novel.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/20.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import Foundation
import CoreData

class Novel: NSManagedObject {
    @NSManaged var name: String?
    @NSManaged var source: Source?
    @NSManaged var contentsUrl: String?
    @NSManaged var contents: NSOrderedSet?
    @NSManaged var avatar: NSData?
    @NSManaged var order: String?
    @NSManaged var updates: String?
    @NSManaged var lastViewChapter: Chapter?
    var isCaching = false
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<Novel> {
        return NSFetchRequest<Novel>(entityName: "Novel")
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    func addChapter(chapter: Chapter) {
        chapter.novel = self
    }
    
    func cache(update: Bool, background: ((Float) -> Void)? = nil) -> Bool {
        let sum = self.contents!.count
        for (index, chapter) in self.contents!.enumerated() {
            let chapter = chapter as! Chapter
            if update || chapter.content == nil {
                if !chapter.cache() {
                    return false
                }
            }
            if background != nil {
                background!(Float(index) / Float(sum))
            }
        }
        return true
    }
    
    func update() -> Bool {
        let contents = SimpleSpider.getContents(url: self.contentsUrl!)
        guard contents != nil else {
            return false
        }
        var contents_old = [String: (url: String, index: Int)]()
        for (index, chapter) in self.contents!.enumerated() {
            let chapter = chapter as! Chapter
            contents_old[chapter.title!] = (chapter.url!, index)
        }
        var updates = 0
        for (title, url) in contents! {
            if contents_old[title] == nil {
                updates += 1
                let chapter = Chapter(context: self.managedObjectContext!)
                chapter.title = title
                chapter.url = url
                self.addChapter(chapter: chapter)
            } else if contents_old[title]!.url != url {
                updates += 1
                let chapter = self.contents![contents_old[title]!.index] as! Chapter
                chapter.url = url
                if chapter.content != nil {
                    chapter.content = SimpleSpider.getChapter(url: url)
                    guard chapter.content != nil else {
                        self.updates = "\(Int(self.updates ?? "0")! + updates)"
                        return false
                    }
                }
            }
        }
        self.updates = "\(Int(self.updates ?? "0")! + updates)"
        return true
    }
    
    func removeCache() {
        for chapter in self.contents! {
            (chapter as! Chapter).content = nil
        }
    }
}
