//
//  ViewModelProtocol.swift
//  todoApp
//
//  Created by 조영태 on 2022/10/03.
//

import Foundation
import RxSwift

protocol ViewModelProtocol {
    associatedtype Input
    associatedtype Output
    
    var input:Input {get}
    var output:Output {get}
    var disposeBag:DisposeBag {get set}
}
