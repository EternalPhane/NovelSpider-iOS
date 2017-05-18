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
    @NSManaged var lastViewChapter: Chapter?
    @NSManaged var lastViewOffset: NSData?
    var isCaching = false
    
    var updates: Int {
        var updates = 0
        for chapter in self.contents! {
            if (chapter as! Chapter).isNew {
                updates += 1
            }
        }
        return updates
    }
    
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
        var oldContents = [String: [String]]()
        var oldContentsIndex = [String: Int]()
        for (index, chapter) in self.contents!.enumerated() {
            let chapter = chapter as! Chapter
            if oldContents[chapter.title!] == nil {
                oldContents[chapter.title!] = [chapter.url!]
            } else {
                oldContents[chapter.title!]!.append(chapter.url!)
            }
            oldContents[chapter.url!] = [chapter.title!]
            oldContentsIndex[chapter.url!] = index
        }
        let newContents = NSMutableOrderedSet()
        for (title, url) in contents! {
            var chapter: Chapter!
            if oldContents[title] == nil {
                if oldContents[url] == nil {
                    chapter = Chapter(context: self.managedObjectContext!)
                    chapter.title = title
                    chapter.url = url
                    chapter.isNew = true
                    self.addChapter(chapter: chapter)
                } else {
                    chapter = self.contents![oldContentsIndex[url]!] as! Chapter
                    chapter.title = title
                }
            } else {
                if oldContents[url] == nil {
                    chapter = Chapter(context: self.managedObjectContext!)
                    chapter.title = title
                    chapter.url = url
                    chapter.isNew = true
                } else {
                    chapter = self.contents![oldContentsIndex[url]!] as! Chapter
                }
            }
            newContents.add(chapter)
        }
        for chapter in newContents {
            let chapter = chapter as! Chapter
            if oldContents[chapter.url!] != nil {
                oldContents[chapter.url!] = nil
            }
        }
        for chapter in self.contents! {
            let chapter = chapter as! Chapter
            if oldContents[chapter.url!] != nil {
                self.managedObjectContext!.delete(chapter)
            }
        }
        self.contents = newContents
        return true
    }
    
    func removeCache() {
        for chapter in self.contents! {
            (chapter as! Chapter).content = nil
        }
    }
}
