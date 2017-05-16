//
//  NovelTableViewCell.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/17.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit

class NovelTableViewCell: UITableViewCell {
    //MARK: Properties
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cacheProgressView: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cacheProgressView.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
