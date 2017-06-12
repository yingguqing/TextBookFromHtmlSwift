//
//  AppStatus.swift
//  TextBookFromHtml
//
//  Created by 影孤清 on 2017/6/10.
//  Copyright © 2017年 影孤清. All rights reserved.
//

import Cocoa


class AppStatus: NSObject {
    static let shareAppStatus = AppStatus()
    public var ruleFile:RuleFile?
    
    private override init() {}
}
