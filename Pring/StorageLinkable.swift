//
//  StorageLinkable.swift
//  Pring
//
//  Created by 1amageek on 2017/11/06.
//  Copyright © 2017年 Stamp Inc. All rights reserved.
//

import FirebaseFirestore
import FirebaseStorage

public struct UploadContainer {

    static var queueLabel: String {
        return "Pring.upload.queue." + UUID().uuidString
    }

    let queue: DispatchQueue = DispatchQueue(label: queueLabel)

    let group: DispatchGroup = DispatchGroup()

    var tasks: [String: StorageUploadTask] = [:]

    var timeout: Int = 30 // Default 30s

    var error: Error? = nil {
        didSet {
            tasks.forEach({ (_, task) in
                task.cancel()
            })
        }
    }

    func wait(_ block: ((Error?) -> Void)?) {
        queue.async {
            self.group.notify(queue: DispatchQueue.main, execute: {
                block?(self.error)
            })
            switch self.group.wait(timeout: .now() + .seconds(self.timeout)) {
            case .success: break
            case .timedOut:
                self.tasks.forEach({ (_, task) in
                    task.cancel()
                })
                let error: DocumentError = DocumentError(kind: .timeout, description: "Save the file timeout.")
                DispatchQueue.main.async {
                    block?(error)
                }
            }
        }
    }
}

public protocol StorageLinkable {

    var hasFiles: Bool { get }

    @discardableResult
    func saveFiles(container: UploadContainer?, block: ((Error?) -> Void)?) -> [String: StorageUploadTask]
}

extension StorageLinkable {

    public var timeout: Int { return 30 }
}
