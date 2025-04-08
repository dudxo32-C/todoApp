//
//  DateInputStackView.swift
//  todoApp
//
//  Created by 조영태 on 4/2/25.
//

import Foundation
import UIKit
import RxCocoa
import SnapKit
import Then
import RxGesture
import RxSwift


class DateInputStackView: UIStackView {
    let datePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .inline  // iOS 14 이상에서 캘린더 스타일
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.isHidden = true
    }

     let dateLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = UIColor.lightGray
    }
    
    private let divider = UIView().then {
        $0.backgroundColor = UIColor.lightGray
        $0.isHidden = true
        $0.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
    }
    
    // MARK: - RX
    private let isDatePickerVisible = BehaviorRelay(value: false)
    private let isInitialDate : BehaviorRelay<Bool>
    
    /// datePicker 가 열린 상태에서 바뀐 date 값 전달
    let changedDateRX: Observable<ControlProperty<Date>.Element>

    private let disposeBag = DisposeBag()

    init(_ date:Date? = nil) {
        self.isInitialDate = BehaviorRelay(value: date != nil)
        
        self.changedDateRX = Observable.combineLatest(
            self.datePicker.rx.date,
            self.isDatePickerVisible
        )
        .filter { $0.1 }
        .map { $0.0 }
        
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 16
        layoutMargins = .init(top: 16, left: 8, bottom: 16, right: 8)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 8
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        
        self.datePicker.date = date ?? Date()
        
        // label 초기 색 설정
        self.dateLabel.textColor = date == nil ? .lightGray : .black
        
        // label 초기 값 설정
        self.dateLabel.text = {
            if let date = date {
                return self.dateToString(date)
            } else {
                return I18N.selectDate
            }
        }()
        
        
        setupUI()
        dateLabelBinding()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addArrangedSubview(self.dateLabel)
        addArrangedSubview(self.divider)
        addArrangedSubview(self.datePicker)
    }
    
    private func dateLabelBinding() {
        self.dateLabel.rx.tapGesture()
            .when(.recognized)
            .observe(on: MainScheduler.instance)
            .bind { _ in self.toggleDatePicker() }
            .disposed(by: disposeBag)
        
        // datePicker 값 label에 설정
        self.changedDateRX
            .asDriver(onErrorJustReturn: Date())
            .map(dateToString(_:))
            .drive(self.dateLabel.rx.text)
            .disposed(by: disposeBag)

        // output date 값에 따른 label 색 설정
        self.changedDateRX
            .asDriver(onErrorJustReturn: Date())
            .map { _ in UIColor.black }
            .drive(self.dateLabel.rx.textColor)
            .disposed(by: disposeBag)
    }
    
    private func toggleDatePicker() {
        let targetVisible = !self.isDatePickerVisible.value
        self.isDatePickerVisible.accept(targetVisible)

        UIView.animate(withDuration: 0.3) {
            self.divider.isHidden = !targetVisible
            self.datePicker.isHidden = !targetVisible
            
            // 애니메이션 효과 적용
            self.layoutIfNeeded()
        }
    }
    
    private func dateToString(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMMM dd, EEEE"
        formatter.locale = Locale(identifier: "ko")

        return formatter.string(from: date)
    }
}
