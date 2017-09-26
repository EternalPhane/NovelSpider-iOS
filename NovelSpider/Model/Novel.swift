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
    @NSManaged var lastViewOffset: NSData?
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<Novel> {
        return NSFetchRequest<Novel>(entityName: "Novel")
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    func addChapter(chapter: Chapter) {
        chapter.novel = self
    }
    
    func cache(background: @escaping (Float) -> Void) -> Bool {
        let sum = self.contents!.count
        var progress: UInt = 0
        var result = true
        let group = DispatchGroup()
        let source = DispatchSource.makeUserDataAddSource()
        source.setEventHandler() {
            progress += source.data
            background(Float(progress) / Float(sum))
        }
        source.resume()
        DispatchQueue.concurrentPerform(iterations: sum) { (index) in
            autoreleasepool {
                guard result else {
                    return
                }
                let chapter = self.contents![index] as! Chapter
                group.enter()
                if chapter.content == nil {
                    if !chapter.cache() {
                        result = false
                    }
                }
                source.add(data: 1)
                group.leave()
            }
        }
        group.wait()
        return result
    }
    
    func update(background: ((Float) -> Void)?) -> Bool {
        var background = background
        if background == nil {
            background = { _ in }
        }
        let contents = SimpleSpider.getContents(url: self.contentsUrl!)
        background!(0.4)
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
        for (offset: index, element: (title: title, url: url)) in contents!.enumerated() {
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
            background!(0.4 + Float(index) / Float(contents!.count) * 0.4)
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
        background!(0.9)
        var updates = 0
        for chapter in self.contents! {
            if (chapter as! Chapter).isNew {
                updates += 1
            }
        }
        self.updates = "\(updates)"
        background!(1.0)
        return true
    }
    
    func removeCache() {
        for chapter in self.contents! {
            (chapter as! Chapter).content = nil
        }
    }
}
