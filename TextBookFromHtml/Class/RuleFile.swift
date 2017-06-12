//
//  RuleFile.swift
//  TextBookFromHtml
//
//  Created by 影孤清 on 2017/6/10.
//  Copyright © 2017年 影孤清. All rights reserved.
//

import Cocoa

fileprivate enum RuleKey {
    static let BookBaseURLKey = "小说源网址"
    static let DirectoryHeaderCutStringKey = "目录保留开始"
    static let DirectoryEncodingKey = "目录读取格式"//(UTF-8等)
    static let DirectoryRegexKey = "目录正则表达式"
    static let ArticleEncodingKey = "文章读取格式"
    static let ArticleStartStringKey = "文章开始"
    static let ArticleEndStringKey = "文章结束"
    static let WebsiteDescriptionKey = "小说网站说明"
    static let RuleFileName = "BookRule.plist"
}

class RuleFile: NSObject {
    var bookName:String?//小说名
    var bookBaseUrl:String?
    private var _directoryUrl:String? //小说目录地址
    var directoryUrl:String? {//小说目录地址
        set(newValue) {
            _directoryUrl = newValue
        }
        get {
            return bookBaseUrl! + _directoryUrl!
        }
    }
    var directoryIsUtf8 = true//目录读取格式(UTF-8等)
    var directoryHeaderCutString:String?//目录开头去掉文字位置
    var directoryRegex:String?//目录正则表达式
    var articleisUtf8 = true//内容读取格式(UTF-8等)
    var articleStartString:String?//内容开始字符串
    var articleEndString:String?//内容结束字符串
    var websiteDescription:String?//小说网站说明
    var isHasRuleFile:Bool = false//是否存在规则信息
    
    init(withBookBaseURL url: String) {
        super.init()
        if let dic = RuleFile.readRuleFileWith(url: url) {
            bookBaseUrl = dic[RuleKey.BookBaseURLKey] as? String
            directoryHeaderCutString = dic[RuleKey.DirectoryHeaderCutStringKey] as? String
            directoryIsUtf8 = Int(dic[RuleKey.DirectoryEncodingKey] as! NSNumber) == 4
            directoryRegex = dic[RuleKey.DirectoryRegexKey] as? String
            articleisUtf8 = Int(dic[RuleKey.ArticleEncodingKey] as! NSNumber) == 4
            articleStartString = dic[RuleKey.ArticleStartStringKey] as? String
            articleEndString = dic[RuleKey.ArticleEndStringKey] as? String
            websiteDescription = dic[RuleKey.WebsiteDescriptionKey] as? String
            isHasRuleFile = true
        }
    }
    
    static func readRuleFileWith(url:String) -> NSDictionary? {
        if url.isAnyText() {
            return readAllRuleFileForDictionary()?[url] as? NSDictionary
        }
        return nil
    }
    
    public func saveRuleFile() {
        let fileDic = NSMutableDictionary()
        if let dic = RuleFile.readAllRuleFileForDictionary() {
            fileDic.setDictionary(dic as! [AnyHashable : Any])
        }
        let saveDic = NSMutableDictionary()
        saveDic[RuleKey.BookBaseURLKey] = bookBaseUrl
        saveDic[RuleKey.DirectoryEncodingKey] = NSNumber(integerLiteral: directoryIsUtf8 ? 4 : 1586)
        saveDic[RuleKey.DirectoryHeaderCutStringKey] = directoryHeaderCutString
        saveDic[RuleKey.DirectoryRegexKey] = directoryRegex
        saveDic[RuleKey.ArticleEncodingKey] = NSNumber(integerLiteral: articleisUtf8 ? 4 : 1586)
        saveDic[RuleKey.ArticleStartStringKey] = articleStartString
        saveDic[RuleKey.ArticleEndStringKey] = articleEndString
        saveDic[RuleKey.WebsiteDescriptionKey] = websiteDescription
        fileDic.setObject(saveDic, forKey: bookBaseUrl! as NSCopying)
        let path = RuleFile.pathWith(fileName: RuleKey.RuleFileName)
        fileDic.write(toFile: path, atomically: true)
    }
    
    static func readAllRuleFileForDictionary() -> NSDictionary? {
        let path = pathWith(fileName: RuleKey.RuleFileName)
        let fileManager = FileManager.default
        let success = fileManager.fileExists(atPath: path)
        if !success {
            let defaultPath = Bundle.main.resourcePath?.appending(pathComponent: RuleKey.RuleFileName)
            do {
                try fileManager.copyItem(atPath: defaultPath!, toPath: path)
            } catch _ {
                assert(true, "复制文件出错")
                return nil
            }
        }
        return NSDictionary(contentsOfFile: path)
    }
    
    static func readAllRuleFileForArray() -> Array<RuleFile>? {
        if let dic = readAllRuleFileForDictionary() {
            var array:Array<RuleFile> = Array()
            for (key,_) in dic {
                array.append(RuleFile(withBookBaseURL: key as! String))
            }
            return array
        }
        return nil
    }
    
    static func pathWith(fileName:String?) ->String {
        let usersHomePath = getpwuid(getuid()).pointee.pw_dir
        let usersHomePathString : String = FileManager.default.string(withFileSystemRepresentation: usersHomePath!, length: Int(strlen(usersHomePath)))
        var lastPath:String = "/Desktop/Book/"
        if (fileName?.isAnyText())! {
            lastPath = lastPath + fileName!
        }
        return usersHomePathString.appending(pathComponent: lastPath)
    }
    
}


extension String {
    public func isAnyText() -> Bool {
        return !self.isEmpty
    }
    
    public func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    
    func appending(pathComponent: String) -> String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
}



