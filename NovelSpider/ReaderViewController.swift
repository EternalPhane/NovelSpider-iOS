//
//  ReaderContainerViewController.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/22.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import UIKit
import FontAwesome_swift

class ReaderViewController: UIViewController {
    @IBOutlet weak var contentsView: UIView!
    @IBOutlet weak var readerTextView: UITextView!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var contentsButton: UIBarButtonItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var fontSizeSlider: UISlider!
    @IBOutlet var colorButtons: [UIButton]!
    @IBOutlet weak var contentsViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsViewBottomConstraint: NSLayoutConstraint!
    var contentsViewWidth: CGFloat!
    var toggleBarsGesture: UIGestureRecognizer!
    var toggleContentsGesture: UIGestureRecognizer!
    var toggleSettingsGesture: UIGestureRecognizer!
    var novel: Novel!
    var chapterIndex: Int = 0
    
    override var prefersStatusBarHidden: Bool {
        return self.navigationController!.isToolbarHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentsViewWidth = self.view.bounds.width * 2 / 3
        self.contentsButton.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 20)], for: .normal)
        self.contentsButton.title = String.fontAwesomeIcon(name: .list)
        self.settingsButton.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 20)], for: .normal)
        self.settingsButton.title = String.fontAwesomeIcon(name: .font)
        self.navigationController!.toolbar.isTranslucent = true
        self.navigationController!.navigationBar.isTranslucent = true
        self.navigationController!.setNavigationBarHidden(true, animated: false)
        for button in self.colorButtons {
            button.layer.cornerRadius = button.bounds.height / 2
            button.layer.borderColor = UIColor.cyan.cgColor
        }
        self.readerTextView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(selectChapter), name: NSNotification.Name(rawValue: "selectChapter"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.contentsViewWidthConstraint.constant = 0
        self.contentsView.updateConstraints()
        self.settingsViewBottomConstraint.constant = -self.settingsView.bounds.height
        self.settingsView.updateConstraints()
        self.view.layoutIfNeeded()
        self.navigationItem.title = self.novel.name
        if self.novel.lastViewChapter != nil {
            self.chapterIndex = self.novel.contents!.index(of: self.novel.lastViewChapter!)
        } else {
            self.chapterIndex = 0
        }
        self.displayContent() {
            var fontSize = UserDefaults.standard.float(forKey: "FontSize")
            if fontSize == 0 {
                fontSize = 16
                UserDefaults.standard.set(fontSize, forKey: "FontSize")
                UserDefaults.standard.synchronize()
            }
            self.setReaderTextAttribute(lineSpacing: 10, fontSize: CGFloat(fontSize))
            self.fontSizeSlider.value = fontSize
            var backgroundColor: UIColor!
            if let data = UserDefaults.standard.object(forKey: "BackgroundColor") as? Data {
                backgroundColor = NSKeyedUnarchiver.unarchiveObject(with: data) as! UIColor
            } else {
                backgroundColor = .groupTableViewBackground
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: backgroundColor), forKey: "BackgroundColor")
                UserDefaults.standard.synchronize()
            }
            self.readerTextView.backgroundColor = backgroundColor
            for button in self.colorButtons {
                if button.backgroundColor!.isConvertedEqual(backgroundColor) {
                    button.layer.borderWidth = 2
                }
            }
            var textColor: UIColor!
            var barStyle: UIBarStyle!
            if self.readerTextView.backgroundColor!.isConvertedEqual(.black) {
                barStyle = .black
                textColor = .lightText
            } else {
                barStyle = .default
                textColor = .darkText
            }
            self.readerTextView.textColor = textColor
            self.navigationController!.toolbar.barStyle = barStyle
            self.navigationController!.navigationBar.barStyle = barStyle
            self.toggleBarsGesture = UITapGestureRecognizer(target: self, action: #selector(self.toggleBars))
            self.toggleBarsGesture.cancelsTouchesInView = true
            self.toggleContentsGesture = UITapGestureRecognizer(target: self, action: #selector(self.toggleContents))
            self.toggleContentsGesture.cancelsTouchesInView = true
            self.toggleContentsGesture.isEnabled = false
            self.toggleSettingsGesture = UITapGestureRecognizer(target: self, action: #selector(self.toggleSettings))
            self.toggleSettingsGesture.cancelsTouchesInView = true
            self.toggleSettingsGesture.isEnabled = false
            self.readerTextView.addGestureRecognizer(self.toggleBarsGesture)
            self.readerTextView.addGestureRecognizer(self.toggleContentsGesture)
            self.readerTextView.addGestureRecognizer(self.toggleSettingsGesture)
            self.readerTextView.isSelectable = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let data = self.novel.lastViewOffset {
            self.readerTextView.setContentOffset(NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! CGPoint, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.novel.lastViewChapter = (self.novel.contents![self.chapterIndex] as! Chapter)
        self.novel.lastViewOffset = NSKeyedArchiver.archivedData(withRootObject: self.readerTextView.contentOffset) as NSData
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        self.navigationController!.toolbar.isTranslucent = false
        self.navigationController!.isToolbarHidden = true
        self.navigationController!.toolbar.barStyle = .default
        self.navigationController!.navigationBar.isTranslucent = false
        self.navigationController!.navigationBar.alpha = 1
        self.navigationController!.isNavigationBarHidden = false
        self.navigationController!.navigationBar.barStyle = .default
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ContentsTableViewController {
            viewController.novel = self.novel
        }
    }
    
    @IBAction func contentsButtonTapped(_ sender: UIBarButtonItem) {
        self.toggleContents()
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIBarButtonItem) {
        self.toggleSettings()
    }
    
    @IBAction func fontSizeSliderChanged(_ sender: UISlider) {
        self.readerTextView.font = self.readerTextView.font!.withSize(CGFloat(sender.value.rounded()))
    }
    
    @IBAction func fontSizeSliderTouchUp(_ sender: UISlider) {
        sender.value = sender.value.rounded()
        UserDefaults.standard.set(sender.value, forKey: "FontSize")
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func colorButtonTapped(_ sender: UIButton) {
        self.readerTextView.backgroundColor = sender.backgroundColor
        if !sender.backgroundColor!.isConvertedEqual(.black) {
            self.readerTextView.textColor = .darkText
            self.navigationController!.toolbar.barStyle = .default
            self.navigationController!.navigationBar.barStyle = .default
        } else {
            self.readerTextView.textColor = .lightText
            self.navigationController!.toolbar.barStyle = .black
            self.navigationController!.navigationBar.barStyle = .black
        }
        for button in self.colorButtons {
            button.layer.borderWidth = 0
        }
        sender.layer.borderWidth = 2
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: sender.backgroundColor!), forKey: "BackgroundColor")
        UserDefaults.standard.set(sender.backgroundColor!.isConvertedEqual(.black), forKey: "IsDark")
        UserDefaults.standard.synchronize()
    }
    
    func toggleBars() {
        let flag = !self.navigationController!.isToolbarHidden
        self.readerTextView.panGestureRecognizer.isEnabled = flag
        UIView.animate(withDuration: 0.2, animations: {
            self.navigationController!.isToolbarHidden = flag
            self.navigationController!.isNavigationBarHidden = flag
        }) { (finished) in
            self.navigationController!.toolbar.alpha = flag ? 1 : 0.75
            self.navigationController!.navigationBar.alpha = flag ? 1 : 0.75
        }
    }
    
    func toggleContents() {
        let flag = self.contentsViewWidthConstraint.constant == 0
        self.contentsViewWidthConstraint.constant = flag ? self.contentsViewWidth : 0
        self.toggleBarsGesture.isEnabled = !flag
        self.toggleContentsGesture.isEnabled = flag
        if flag {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeChapter"), object: nil, userInfo: ["index": self.chapterIndex])
        }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    func toggleSettings() {
        let flag = self.settingsViewBottomConstraint.constant == -self.settingsView.bounds.height
        self.settingsViewBottomConstraint.constant = flag ? 0 : -self.settingsView.bounds.height
        self.toggleBarsGesture.isEnabled = !flag
        self.toggleSettingsGesture.isEnabled = flag
        self.readerTextView.panGestureRecognizer.isEnabled = !flag
        if flag {
            self.toggleBars()
        }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    func setReaderTextAttribute(lineSpacing: CGFloat, fontSize: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        self.readerTextView.attributedText = NSAttributedString(string: self.readerTextView.text, attributes: [
            NSFontAttributeName: UIFont.systemFont(ofSize: fontSize),
            NSParagraphStyleAttributeName: paragraph
        ])
    }
    
    func displayContent(completion: (() -> Void)?) {
        let chapter = self.novel.contents![self.chapterIndex] as! Chapter
        let wait = chapter.content == nil || completion != nil
        if wait {
            self.showActivityIndicator(withLabel: true, labelText: "正在加载...")
        }
        chapter.isNew = false
        DispatchQueue.global().async {
            let content = chapter.content ?? SimpleSpider.getChapter(url: chapter.url!)
            DispatchQueue.main.async {
                guard content != nil else {
                    self.readerTextView.text = ""
                    let error = {
                        self.alert(title: "错误", message: "章节加载失败，请检查网络！", okAction: nil)
                    }
                    if wait {
                        self.dismissActivityIndicator(completion: error)
                    } else {
                        error()
                    }
                    if completion != nil {
                        completion!()
                    }
                    return
                }
                self.readerTextView.text = content
                self.readerTextView.scrollRangeToVisible(NSRange(location:0, length:0))
                if completion != nil {
                    completion!()
                }
                if wait {
                    self.dismissActivityIndicator(completion: nil)
                }
            }
        }
    }
    
    func selectChapter(notification: Notification) {
        self.chapterIndex = notification.userInfo!["index"] as! Int
        self.displayContent(completion: nil)
        self.toggleContents()
    }
}

extension ReaderViewController: UITextViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y - scrollView.contentSize.height + scrollView.bounds.height > 100 {
            guard self.chapterIndex + 1 < self.novel.contents!.count else {
                return
            }
            self.chapterIndex += 1
            self.displayContent(completion: nil)
        } else if scrollView.contentOffset.y < -100 {
            guard self.chapterIndex - 1 >= 0 else {
                return
            }
            self.chapterIndex -= 1
            self.displayContent(completion: nil)
        }
    }
}
