//
//  ViewController.swift
//  TextBookFromHtml
//
//  Created by 影孤清 on 2017/6/5.
//  Copyright © 2017年 影孤清. All rights reserved.
//

import Cocoa

class ViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource {
    
    var progress:Float = 0.0
    var finishIndex:Float = 0.0
    var bookList:Array<BookEntity> = Array()
    var chapterFailArr:Array<BookEntity> = Array()
    var ruleFile:RuleFile?
    var ruleFileArray:Array<RuleFile> = Array()
    let queue = DispatchQueue(label: "tk.bourne.testQueue", qos: .utility, attributes: DispatchQueue.Attributes.concurrent)
    
    @IBOutlet weak var lbShow: NSTextField!
    @IBOutlet weak var btnStart: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var lbSelectShow: NSTextField!
    @IBOutlet weak var tfDirectoryUrl: NSTextField!
    @IBOutlet weak var tfBookName: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData()
        // 添加通知
        YNotification.addObserver(observer:self, selector:#selector(ViewController.reloadData), notification:.reloadRuleFileData)
    }

    //MARK:重新获取数据
    func reloadData() {
        ruleFileArray.removeAll()
        ruleFile = nil;
        lbSelectShow.stringValue = ""
        if let a = RuleFile.readAllRuleFileForArray() {
            ruleFileArray += a
        }
        tableView.reloadData()
    }
    
    /**
     *  @brief  检查目录地址,如果有基地址就删除前面的其地址
     *
     *  @param url  目录地址
     *
     *  @return return description
     */
    func cheackDirectoryUrl(url:String) -> String {
        guard (ruleFile?.bookBaseUrl?.isAnyText())! && url.hasPrefix(ruleFile!.bookBaseUrl!) else {
            return url
        }
        let index = url.index(url.startIndex, offsetBy: ruleFile!.bookBaseUrl!.characters.count)
        return url.substring(from: index)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return ruleFileArray.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "RuleFileCellIdentifier", owner: self) as! NSTableCellView
        let item = ruleFileArray[row]
        cell.textField?.stringValue = "    " + item.websiteDescription!
        return cell
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let item = ruleFileArray[row]
        lbSelectShow.stringValue = item.websiteDescription!
        ruleFile = item
        ruleFile?.bookName = tfBookName.stringValue
        ruleFile?.directoryUrl = tfDirectoryUrl.stringValue
        return true
    }
    
    @IBAction func startCreateAction(_ sender: NSButton) {
        guard ruleFile != nil else {
            showFailMessage(msg: "请选择抓取规则")
            btnStart.isEnabled = true;
            return
        }
        guard (ruleFile?.bookName?.isAnyText())! && ((ruleFile?.directoryUrl?.isAnyText()) != nil) else {
            showFailMessage(msg: "请输入小说名和目录地址")
            btnStart.isEnabled = true;
            return
        }
        guard (ruleFile?.isHasRuleFile)! else {
            showFailMessage(msg: "不存在规则数据,请添加")
            btnStart.isEnabled = true;
            return
        }
        sender.isEnabled = false
        createBookFromNet()
    }
    
    /**
     *  @brief  从网上抓取小说
     *
     */
    func createBookFromNet() {
        var muluString = urlstringWith(url: (ruleFile?.directoryUrl)!, isUtf8: (ruleFile?.directoryIsUtf8)!)
        guard muluString.isAnyText() else {
            showFailMessage(msg: "目录数据获取不到")
            btnStart.isEnabled = true;
            return
        }
        finishIndex = 0
        if (ruleFile?.directoryHeaderCutString?.isAnyText())! {
            muluString = cutHeaderWith(str: (ruleFile?.directoryHeaderCutString)!, content: muluString)
        }
        muluCutForRegular(content: muluString)
        let length = bookList.count
        for item in bookList {
            loadBookText(item: item, length: UInt(length))
        }
    }
    
    /**
     *  @brief  切掉前面会造成错误的文字
     *
     *  @param str      正确文字唯一的开始文字
     *  @param content  源文字
     *
     *  @return 结果
     */
    func cutHeaderWith(str:String,content:String) -> String {
        guard str.isAnyText() else {return content}
        let range = content.range(of: str)
        guard (range?.upperBound != nil) else {
            return content
        }
        
        return content.substring(from: (range?.upperBound)!)
    }
    
    /**
     *  @brief  以正则表达式来分割目录
     *  (因为不会写正则表达式,所以很少使用,不过最后还是使用这个方法,修改比较容易)
     *
     *  @param content  源文字
     *
     */
    func muluCutForRegular(content:String) {
        bookList.removeAll()
        do {
            let regex = try NSRegularExpression(pattern: (ruleFile?.directoryRegex)!, options: .caseInsensitive)
            let matches = regex.matches(in: content, options: .reportProgress, range: NSMakeRange(0, content.characters.count))
            var range:Range<String.Index>?
            for m in matches {
                let item = BookEntity()
                let url = content.substring(with:content.range(from: m.rangeAt(1))!)
                range = url.range(of: "\"")
                if range?.lowerBound != nil {
                    item.url = url.substring(to: (range?.lowerBound)!)
                    range = nil
                } else {
                    item.url = url
                }
                item.title = content.substring(with:content.range(from: m.rangeAt(2))!)
                bookList.append(item)
            }
        } catch _ {
            print("解析目录出错")
        }
    }
    
    /**
     *  @brief  抓取当前章节内容
     *
     *  @param item    当前章节信息
     *  @param length  总章节数
     *
     */
    func loadBookText(item:BookEntity, length:UInt) {
        queue.async {
            let url = (self.ruleFile?.bookBaseUrl)! + item.url!
            var str = self.urlstringWith(url: url, isUtf8: (self.ruleFile?.articleisUtf8)!)
            self.finishIndex += 1
            var isFail = true
            if str.isAnyText() {
                str = str.replacingOccurrences(of: "&nbsp;", with: "  ")
                str = str.replacingOccurrences(of: "<br />", with: "\n")
                str = str.replacingOccurrences(of: "<br/>", with: "\n")
                str = str.replacingOccurrences(of: "\n\n;", with: "\n")
                var range = str.range(of: (self.ruleFile?.articleStartString)!)//内容开始字符串
                if range?.lowerBound != nil {
                    var text = str.substring(from: range!.upperBound)
                    range = text.range(of: (self.ruleFile?.articleEndString)!)//内容结束字符串
                    if range?.lowerBound != nil {
                        text = text.substring(to: (range?.lowerBound)!)
                        if text.isAnyText() {
                            item.text = text
                            isFail = false
                        }
                    }
                }
            }
            if isFail {
                self.chapterFailArr.append(item)
            }
            DispatchQueue.main.async {
                let p = self.finishIndex*100/Float(length)
                self.lbShow.stringValue = String(format:"进度: %.2f%%",p)
                if (p >= 100) {
                    self.saveBook()
                    self.btnStart.isEnabled = true;
                    if self.chapterFailArr.count > 0 {
                        self.showFailMessage(msg: "有章节内容没有获取成功,请查看LOG")
                        self.btnStart.isEnabled = true;
                        print("以下章节没有获取到内容")
                        for item in self.chapterFailArr {
                            print(item.title!+item.url!)
                        }
                    }
                }
            }
        }
    }
    
    /**
     *  @brief  保存小说
     *
     */
    func saveBook() {
        var str = ""
        for item in bookList {
            str = str + item.title! + "\n" + item.text! + "\n"
        }
        let path = RuleFile.pathWith(fileName: ((ruleFile?.bookName)! + ".txt"))
        do {
            try str.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
        } catch _ {
            lbShow.stringValue = "小说写文件时失败"
        }
        lbShow.stringValue = "小说收集完成"
    }
    
    /**
     *  @brief  通过url获取数据,内容为文字
     *
     *  @param strurl  strurl description
     *
     *  @return return description
     */
    func urlstringWith(url strurl:String , isUtf8:Bool) -> String {
        let url = URL(string: strurl)
        do {
            let data = try Data(contentsOf: url!)
            if isUtf8 {
                return String(data:data, encoding:String.Encoding.utf8)!
            } else {
                let enc = CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
                return String(data:data, encoding:String.Encoding(rawValue: enc))!
            }
        } catch _ {
            print("从网络获取数据失败  \(strurl)")
            return ""
        }
    }
    
    
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        let select = tableView.selectedRow
        if select  < 0 {
            AppStatus.shareAppStatus.ruleFile = nil
        } else {
            AppStatus.shareAppStatus.ruleFile = ruleFileArray[select]
        }
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
}

extension NSViewController {
    public func showFailMessage(msg:String) {
        present(message: msg, stytle: .critical)
    }
    
    /**
     *  @brief  显示提示框
     *
     *  @param message  显示内容
     *  @param style    提示框类型
     *
     */
    public func present(message:String , stytle:NSAlertStyle) {
        let alert = NSAlert()
        alert.messageText = stytle == .informational ? "成功" : "失败"
        alert.informativeText = message;
        alert.alertStyle = stytle
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}

