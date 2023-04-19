//
//  MorseToTextViewController.swift
//  MorseFlash
//
//  Created by Руслан Садыков on 18.04.2023.
//

import Foundation
import UIKit

final class MorseToTextViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let tapToStartText: String = "Вставьте морзе код в формате \".... . .-.. .-.. ---\""
    }

    // MARK: - UI Elements
    private let topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 20
        stackView.distribution = .fillProportionally
        stackView.axis = .vertical
        return stackView
    }()

    private let morseCodeTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isHidden = true
        textView.autocapitalizationType = .sentences
        return textView
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .systemGray6
        textView.font = UIFont.systemFont(ofSize: 19)
        textView.textAlignment = .center
        textView.text = Constants.tapToStartText
        textView.isEditable = true
        textView.layer.cornerRadius = 8.0
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        textView.textColor = .label
        textView.autocorrectionType = .no
//        textView.smartDashesType = .no
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Создание кнопки с изображением шестеренки
        let settingsButton = UIButton(type: .system)
        settingsButton.setImage(UIImage(systemName: "globe"), for: .normal)
        settingsButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)

        // Добавление действия при нажатии на кнопку
        settingsButton.addTarget(self, action: #selector(showLanguagePicker), for: .touchUpInside)

        // Создание объекта UIBarButtonItem на основе кнопки
        let settingsBarButtonItem = UIBarButtonItem(customView: settingsButton)

        // Добавление кнопки на навигационную панель
        navigationItem.rightBarButtonItem = settingsBarButtonItem

        setupConstraints()

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        view.addGestureRecognizer(tapGesture)

        let swipeDownGesture = UISwipeGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        swipeDownGesture.direction = .down
        view.addGestureRecognizer(swipeDownGesture)
    }

    @objc private func showLanguagePicker() {
        DictionaryManager.shared.showLanguagePicker(from: self) {
            self.textView.delegate?.textViewDidChange?(self.textView)
        }
    }

    private func getDefaultTextViewAttributes(for morseCode: String) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: morseCode)
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        attributedString.addAttributes([
            .foregroundColor: UIColor.label,
            .font: GlobalConstants.morseTextViewFont,
            .paragraphStyle: style
        ], range: NSMakeRange(0, morseCode.count))
        return attributedString
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UITextField {
            return false
        }
        return true
    }

    private func convertMorseCodeToText(_ morseCode: String) -> String {
        let morseWords = morseCode.split(separator: " ")

        var text = ""
        for morseWord in morseWords {
            let localeDictionary: [String: String]
            if let morseDictionary = DictionaryManager.shared.getMorseDictionary(for: DictionaryManager.shared.locale)?.swapKeyValues() {
                localeDictionary = morseDictionary
            } else {
                return GlobalConstants.unsupportedLocale
            }
            let morseCodeDigits = DictionaryManager.morseCodeDigits.swapKeyValues()
            let specialTable = DictionaryManager.specialTable.swapKeyValues()
            switch morseWord {
            case let x where morseCodeDigits.keys.contains(String(x)):
                text += morseCodeDigits[String(x)]!
            case let x where localeDictionary.keys.contains(String(x)):
                text += localeDictionary[String(x)]!
            case let x where specialTable.keys.contains(String(x)):
                text += specialTable[String(x)]!
            default:
                continue
            }
        }

        print("asiodaosdojiasoijdjoiasdjoiajoisdojiasd: ", text)

        return text
    }

    private func isFromConstants(text: String) -> Bool {
        if text == Constants.tapToStartText {
            return true
        } else {
            return false
        }
    }
}

extension MorseToTextViewController {
    private func setupConstraints() {
        view.addSubview(textView)
        view.addSubview(topStackView)

        topStackView.addArrangedSubview(morseCodeTextView)
        topStackView.addArrangedSubview(textView)

        topStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(16)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-GlobalConstants.padding)
        }

        morseCodeTextView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(64)
        }

        textView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(100)
        }
    }
}

// MARK: - UITextViewDelegate
extension MorseToTextViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let morseCode = textView.text ?? ""
        guard !isFromConstants(text: morseCode) else { return }
        print("asidojasoidjasiodjaiosd: ", morseCode)
        let text = convertMorseCodeToText(morseCode)
        let attributedString = getDefaultTextViewAttributes(for: text)
        morseCodeTextView.attributedText = attributedString
        UIView.animate(withDuration: 0.5) {
            self.morseCodeTextView.isHidden = text.isEmpty
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == self.textView {
            textView.textColor = .label
            if isFromConstants(text: textView.text ?? "") {
                textView.text.removeAll()
            }
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = Constants.tapToStartText
        }
    }
}

extension Dictionary where Value: Hashable {

    func swapKeyValues() -> [Value : Key] {
        return Dictionary<Value, Key>(uniqueKeysWithValues: lazy.map { ($0.value, $0.key) })
    }
}
