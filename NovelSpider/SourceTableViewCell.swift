//
//  SourceTableViewCell.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/18.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class SourceTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
