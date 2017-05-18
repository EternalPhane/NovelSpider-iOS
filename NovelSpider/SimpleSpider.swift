//
//  SimpleSpider.swift
//  NovelSpider
//
//  Created by 左宗源 on 2017/4/20.
//  Copyright © 2017年 eternalphane. All rights reserved.
//

import Foundation
import HTMLReader

class SimpleSpider {
    private static let gbk = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
    private static let searchEngines = [
        "百度": (
            url: "https://www.baidu.com/s?wd=",
            pattern: "a[target='_blank'][data-click]"
        ),
        "Bing": (
            url: "http://www.bing.com/search?q=",
            pattern: "a[target='_blank']"
        )
    ]
    private static let regexNewline = try! NSRegularExpression(pattern: "\\n{2,}")
    private static let regexWhite = try! NSRegularExpression(pattern: "\\s*\\n\\s*")
    private static let regexContainer = try! NSRegularExpression(pattern: "</?(div|th|td|li|p)")
    private static let regexChapterTitle = try! NSRegularExpression(pattern: "(第|^)[序〇零一二三四五六七八九十百千0-9]+?[章节. ]")
    
    private class func getUrl(_ url: String) -> String {
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "HEAD"
        req.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        req.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/602.3.12 (KHTML, like Gecko) Version/10.0.2 Safari/602.3.12", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 10
        req.httpShouldUsePipelining = true
        var redirectedUrl = url
        let sema = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { (data, response, error) in
            if response != nil {
                redirectedUrl = response!.url!.absoluteString
            }
            sema.signal()
        }.resume()
        sema.wait()
        return redirectedUrl
    }
    
    private class func getHtml(_ url: String) -> HTMLDocument? {
        let url = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        var req = URLRequest(url: url!)
        req.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        req.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/602.3.12 (KHTML, like Gecko) Version/10.0.2 Safari/602.3.12", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 10
        req.httpShouldUsePipelining = true
        var html: String?
        let sema = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard data != nil else {
                sema.signal()
                return
            }
            for encoding in [String.Encoding.utf8, SimpleSpider.gbk] {
                html = String(data: data!, encoding: encoding)
                if html != nil {
                    break
                }
            }
            sema.signal()
        }.resume()
        sema.wait()
        return html == nil ? nil : HTMLDocument(string: html!)
    }
    
    class func getContentsUrl(name: String, source: String, searchEngine: String = "Bing", maxDepth: Int = 3) -> String? {
        guard let doc = SimpleSpider.getHtml("\(SimpleSpider.searchEngines[searchEngine]!.url)\"\(name)\" site:\(source)") else {
            return nil
        }
        var stack = [String]()
        var visited = Set<String>()
        var queue = [String]()
        for link in doc.nodes(matchingSelector: SimpleSpider.searchEngines[searchEngine]!.pattern) {
            if link.textContent.localizedStandardContains(name) {
                queue.insert(SimpleSpider.getUrl(link["href"]), at: 0)
            }
        }
        stack += queue
        queue.removeAll()
        var depth = 1
        while !stack.isEmpty {
            let url = stack.popLast()
            guard url != "" else {
                depth -= 1
                continue
            }
            guard !visited.contains(url!) else {
                continue
            }
            visited.insert(url!)
            guard let doc = SimpleSpider.getHtml(url!) else {
                continue
            }
            let title = doc.firstNode(matchingSelector: "title")!.textContent
            if (try! NSRegularExpression(pattern: "([^\\p{Han}]|^)\(name)")).numberOfMatches(in: title, range: NSRange(location: 0, length: title.characters.count)) > 0 {
                var i = 0
                for link in doc.nodes(matchingSelector: "a") {
                    let text = link.textContent
                    if SimpleSpider.regexChapterTitle.numberOfMatches(in: text, range: NSRange(location: 0, length: text.characters.count)) > 0 {
                        i += 1
                    }
                    if i > 2 {
                        if doc.textContent.localizedStandardContains(name) {
                            return url
                        }
                        break
                    }
                }
            }
            guard depth < maxDepth else {
                continue
            }
            let baseUrl = URL(string: url!)
            for link in doc.nodes(matchingSelector: "a") {
                let text = link.textContent
                if (try! NSRegularExpression(pattern: "\(name)|目录|书页")).numberOfMatches(in: text, range: NSRange(location: 0, length: text.characters.count)) > 0 {
                    if let url = URL(string: link["href"], relativeTo: baseUrl) {
                        queue.insert(url.absoluteString, at: 0)
                    }
                }
            }
            queue.insert("", at: 0)
            stack += queue
            depth += 1
            queue.removeAll()
        }
        return nil
    }
    
    class func getContents(url: String) -> [(title: String, url: String)]? {
        var contents = [(title: String, url: String)]()
        var set = Set<String>()
        let baseUrl = URL(string: url)
        let doc = SimpleSpider.getHtml(url)
        guard doc != nil else {
            return nil
        }
        for link in doc!.nodes(matchingSelector: "a") {
            let text = link.textContent
            if SimpleSpider.regexChapterTitle.numberOfMatches(in: text, range: NSRange(location: 0, length: text.characters.count)) > 0 {
                if let url = URL(string: link["href"], relativeTo: baseUrl) {
                    if !set.contains(text) {
                        contents.append((text, url.absoluteString))
                        set.insert(text)
                    }
                }
            }
        }
        guard contents.count != 0 else {
            return nil
        }
        return contents
    }
    
    class func getChapter(url: String) -> String? {
        let raw_doc = SimpleSpider.getHtml(url)
        guard raw_doc != nil else {
            return nil
        }
        var html = raw_doc!.innerHTML
        html = SimpleSpider.regexWhite.stringByReplacingMatches(in: html, range: NSRange(location: 0, length: html.characters.count), withTemplate: "")
        let doc = HTMLDocument(string: SimpleSpider.regexContainer.stringByReplacingMatches(in: html, range: NSRange(location: 0, length: html.characters.count), withTemplate: "\n$0"))
        for node in doc.nodes(matchingSelector: "a, script, style") {
            node.removeFromParentNode()
        }
        for node in doc.nodes(matchingSelector: "br") {
            node.textContent = "\n"
        }
        let text = doc.bodyElement!.textContent
        return SimpleSpider.regexNewline.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: text.characters.count), withTemplate: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    class func getAvatar(name: String) -> NSData? {
        guard let doc = getHtml("http://www.yousuu.com/search/\(name)?type=book") else {
            return nil
        }
        var url: URL?
        for node in doc.nodes(matchingSelector: "div.booklist-subject") {
            if node.firstNode(matchingSelector: "div.title")!.textContent == name {
                url = URL(string: node.firstNode(matchingSelector: "img")!["src"])
                break
            }
        }
        guard url != nil else {
            return nil
        }
        var avatar: NSData?
        let sema = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            avatar = data != nil ? NSData(data: data!) : nil
            sema.signal()
            }.resume()
        sema.wait()
        return avatar
    }
}
