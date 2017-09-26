//
//  UIViewExtension.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/19.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit
import CoreData

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return self.topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return self.topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return self.topViewController(controller: presented)
        }
        return controller
    }
}

extension UIViewController {
    var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func alert(title: String, message: String?, okAction: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .cancel) { (result) in
            if okAction != nil {
                okAction!()
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func showActivityIndicator(withLabel: Bool = false, labelText: String = "") {
        let storyboard = UIStoryboard(name: "ActivityIndicator", bundle: nil)
        var controller: UIViewController
        var completion: (() -> Void)?
        if withLabel {
            controller = storyboard.instantiateViewController(withIdentifier: "LabeledActivityIndicator")
            completion = {
                (controller as! LabeledActivityIndicatorViewController).infoLabel.text = labelText
            }
        } else {
            controller = storyboard.instantiateViewController(withIdentifier: "ActivityIndicator")
        }
        self.present(controller, animated: true, completion: completion)
    }
    
    func dismissActivityIndicator(completion: (() -> Void)?) {
        DispatchQueue.global().async {
            while self.presentedViewController == nil || !self.presentedViewController!.isViewLoaded {
            }
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: completion)
            }
        }
    }
}

extension UITableViewCell {
    var indexPath: IndexPath {
        return (superview as! UITableView).indexPath(for: self)!
    }
    
    func showAccesoryBadge(badge: String) {
        let accesoryBadge = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        accesoryBadge.text = badge
        accesoryBadge.textColor = .white
        accesoryBadge.font = accesoryBadge.font.withSize(16)
        accesoryBadge.textAlignment = .center
        accesoryBadge.backgroundColor = .red
        accesoryBadge.sizeToFit()
        if accesoryBadge.frame.width < accesoryBadge.frame.height {
            accesoryBadge.frame.size.width = accesoryBadge.frame.height
        }
        accesoryBadge.layer.cornerRadius = accesoryBadge.frame.height / 2
        accesoryBadge.clipsToBounds = true
        self.accessoryView = accesoryBadge
        self.layoutIfNeeded()
        self.tag = 1
    }
}

extension UIColor {
    func isConvertedEqual(_ color: UIColor) -> Bool {
        guard let space = self.cgColor.colorSpace else {
            return false
        }
        guard let converted = color.cgColor.converted(to: space, intent: .absoluteColorimetric, options: nil) else {
            return false
        }
        return self.cgColor == converted
    }
}
