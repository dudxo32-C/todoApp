//
//  TodoRealm.swift
//  todoApp
//
//  Created by 조영태 on 3/11/25.
//

import Foundation
import RealmSwift


class TodoRealm: Object {
    @Persisted(primaryKey: true) var _id: String
    @Persisted var title: String
    @Persisted var date: Date
    @Persisted var contents: String
    
    convenience init(title: String, date: Date, contents: String) {
        self.init()
        self._id = UUID().uuidString
        self.title = title
        self.date = date
        self.contents = contents
    }
}
