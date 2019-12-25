//
//  Activity.swift
//  Eyes Tracking
//
//  Created by Shaheed on 7/28/19.
//  Copyright © 2019 virakri. All rights reserved.
//

import UIKit

class Activity {
    
    // Mark: Enum - Activity Types
    static let TYPE_TAP = "tap"
    static let TYPE_SCROLL = "scroll"
    static let TYPE_DISTRACTED = "distracted"
    static let TYPE_LOOKING = "looking"
    static let TYPE_URL_CHANGE = "url_change"
    
    // MARK: Properties
    var type: String
    var timeStamp: Int
    var metaData: [String: Any]
    
    init(type: String, timeStamp: Int, metaData: [String: Any]) {
        self.type = type
        self.timeStamp = timeStamp
        self.metaData = metaData
    }
    
    var parse: [String: Any] {
        return [
            "type": self.type,
            "timeStamp": self.timeStamp,
            "metaData": self.metaData
        ]
    }
    
    static func toJson(activities: [Activity]) -> [[String: Any]] {
        var json: [[String: Any]] = []
        for (_, activity) in activities.enumerated() {
            json.append(activity.parse)
        }
        return json
    }
    
}
