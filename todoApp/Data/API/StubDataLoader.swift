//
//  StubDataLoader.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation

final class SampleDataLoader {
    static func loadJSON(named fileName: String) -> Data {
        guard
            let url = Bundle.main.url(
                forResource: fileName,
                withExtension: "json"
            )
        else {
            fatalError("Missing file: \(fileName).json")
        }
        return try! Data(contentsOf: url)
    }
}
