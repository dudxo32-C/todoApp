//
//  StringEX.swift
//  todoApp
//
//  Created by 조영태 on 4/3/25.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
