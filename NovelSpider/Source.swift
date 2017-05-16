//
//  Source.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/20.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import Foundation
import CoreData

class Source: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var url: String?
    @NSManaged public var novels: NSSet?
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<Source> {
        return NSFetchRequest<Source>(entityName: "Source")
    }
}
