//
//  LoadingTask.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation

struct LoadingTask {
    enum TaskType {
        case local
        case remote
    }
    
    let taskType: TaskType
    let range: NSRange
    init(taskType: TaskType, range: NSRange) {
        self.taskType = taskType
        self.range = range
    }
    
    static func == (lhs: LoadingTask, rhs: LoadingTask) -> Bool {
        return (lhs.taskType == rhs.taskType) && (lhs.range == rhs.range)
    }
}
