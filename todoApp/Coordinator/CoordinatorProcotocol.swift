//
//  CoordinatorProcotocl.swift
//  todoApp
//
//  Created by 조영태 on 5/1/25.
//

import Foundation
import UIKit
import RxSwift

protocol CoordinatorProcotcol: AnyObject {
    var navigationController: UINavigationController { get }
    var disposeBag: DisposeBag { get }
    
    func start()
}
