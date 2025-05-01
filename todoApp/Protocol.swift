//
//  IOProtocol.swift
//  todoApp
//
//  Created by 조영태 on 5/1/25.
//

import Foundation
import RxSwift

struct Empty {}

protocol HasRxIO {
    associatedtype Input
    associatedtype Output

//    var input: Input { get }
//    var output: Output { get }
    
    var disposeBag: DisposeBag { get }
}
