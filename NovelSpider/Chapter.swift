//
//  Chapter.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/20.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import Foundation
import CoreData

class Chapter: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var content: String?
    @NSManaged var novel: Novel?
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<Chapter> {
        return NSFetchRequest<Chapter>(entityName: "Chapter")
    }
    
    func cache() -> Bool {
        self.content = SimpleSpider.getChapter(url: self.url!)
        return self.content != nil
    }
}
