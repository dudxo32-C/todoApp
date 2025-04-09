//
//  AppDIContainer.swift
//  todoApp
//
//  Created by 조영태 on 4/8/25.
//

import Foundation
import Swinject

final class AppDIContainer {
    let container = Container()
    
    init() {
        _  = Assembler([
            // 전역 공통 의존성 (예: 네트워크, 유틸 등)
        ], container: container)
    }}
