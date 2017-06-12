//
//  RuleFileViewController.swift
//  TextBookFromHtml
//
//  Created by 影孤清 on 2017/6/10.
//  Copyright © 2017年 影孤清. All rights reserved.
//

import Cocoa

class RuleFileViewController: NSViewController {

    var ruleFile:RuleFile?
    var isExist:Bool = false
    
    @IBOutlet weak var tfWebsiteDescript: NSTextField!
    @IBOutlet weak var tfBaseURL: NSTextField!
    @IBOutlet weak var tfDirectoryHeaderCut: NSTextField!
    @IBOutlet weak var lbDirectoryEncoding: NSTextField!
    @IBOutlet weak var tfDirectoryRegex: NSTextField!
    @IBOutlet weak var tfArticleStart: NSTextField!
    @IBOutlet weak var tfArticleEnd: NSTextField!
    @IBOutlet weak var lbArticleEncoding: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ruleFile = AppStatus.shareAppStatus.ruleFile!
        if ruleFile != nil {
            tfWebsiteDescript.stringValue = (ruleFile?.websiteDescription!)!
            tfBaseURL.stringValue = (ruleFile?.bookBaseUrl!)!
            tfDirectoryHeaderCut.stringValue = (ruleFile?.directoryHeaderCutString!)!
            lbDirectoryEncoding.stringValue = (ruleFile?.directoryIsUtf8)! ? "UTF-8" : "GBK"
            tfDirectoryRegex.stringValue = (ruleFile?.directoryRegex!)!
            tfArticleStart.stringValue = (ruleFile?.articleStartString!)!
            tfArticleEnd.stringValue = (ruleFile?.articleEndString!)!
            lbArticleEncoding.stringValue = (ruleFile?.articleisUtf8)! ? "UTF-8" : "GBK"
        }
    }
    
    
    @IBAction func utfAction(_ sender: NSButton) {
        if (sender.tag == 0) {
            lbDirectoryEncoding.stringValue = sender.title;
        } else {
            lbArticleEncoding.stringValue = sender.title;
        }
    }
    
    @IBAction func gbkAction(_ sender: NSButton) {
        if (sender.tag == 0) {
            lbDirectoryEncoding.stringValue = sender.title;
        } else {
            lbArticleEncoding.stringValue = sender.title;
        }
    }
    
    @IBAction func saveAction(_ sender: NSButton) {
        guard tfWebsiteDescript.stringValue.isAnyText() else {
            showFailMessage(msg: "请输入--网站名称")
            return
        }
        guard tfBaseURL.stringValue.isAnyText() else {
            showFailMessage(msg: "请输入--小说网站主地址")
            return
        }
        guard tfDirectoryRegex.stringValue.isAnyText() else {
            showFailMessage(msg: "请输入--目录正则表达式")
            return
        }
        guard tfArticleStart.stringValue.isAnyText() else {
            showFailMessage(msg: "请输入--文章开始")
            return
        }
        guard tfArticleEnd.stringValue.isAnyText() else {
            showFailMessage(msg: "请输入--文章结束")
            return
        }
        updateNewRuleFile(f: ruleFile)
    }
    
    /**
     *  @brief  修改规则信息,如果没有就是新增
     *
     *  @param file  file description
     *
     */
    func updateNewRuleFile(f:RuleFile?) {
        var file = f
        let baseUrl = tfBaseURL.stringValue
        if file == nil {
            file = RuleFile(withBookBaseURL: baseUrl)
        }
        // 有新网站的时候,更新以下信息
        file?.bookBaseUrl = baseUrl;	// 小说网站地址
        file?.directoryIsUtf8 = "UTF-8" == lbDirectoryEncoding.stringValue
        file?.directoryHeaderCutString = tfDirectoryHeaderCut.stringValue// 目录开头去掉文字位置
        file?.directoryRegex = tfDirectoryRegex.stringValue// 目录正则表达式
        file?.articleisUtf8 = "UTF-8" == lbArticleEncoding.stringValue
        file?.articleStartString = tfArticleStart.stringValue	// 内容开始字符串
        file?.articleEndString = tfArticleEnd.stringValue	// 内容结束字符串
        file?.websiteDescription = tfWebsiteDescript.stringValue	// 小说网站说明
        isExist = (file?.isHasRuleFile)!
        file?.saveRuleFile()
        // post 通知
        YNotification.postNotification(notification:.reloadRuleFileData)
        let msg = isExist ? "修改规则成功" : "添加规则成功"
        present(message: msg, stytle: .informational)
    }
}
