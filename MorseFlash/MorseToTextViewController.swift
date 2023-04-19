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
        static let insertMorseCode = "insertMorseCode".localized
    }

    // MARK: - UI Elements
    private let topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 20
        stackView.distribution = .fillProportionally
        stackView.axis = .vertical
        return stackView
    }()

    private let resultTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isHidden = true
        textView.autocapitalizationType = .sentences
        return textView
    }()

    private lazy var inputMorseCodeTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .systemGray6
        textView.font = UIFont.systemFont(ofSize: 19)
        textView.textAlignment = .center
        textView.text = Constants.insertMorseCode
        textView.isEditable = true
        textView.layer.cornerRadius = 8.0
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        textView.textColor = .label
        textView.autocorrectionType = .no
        textView.smartDashesType = .no
        return textView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRightBarButtonItem()
        setupConstraints()
        setupGestureRecognizers()
    }

    private func setupRightBarButtonItem() {
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
    }

    private func setupGestureRecognizers() {
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

    // MARK: - Handlers
    @objc private func showLanguagePicker() {
        DictionaryManager.shared.showLanguagePicker(from: self) {
            self.inputMorseCodeTextView.delegate?.textViewDidChange?(self.inputMorseCodeTextView)
        }
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

    // MARK: - Functions
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
        return text
    }

    private func isFromConstants(text: String) -> Bool {
        if text == Constants.insertMorseCode {
            return true
        } else {
            return false
        }
    }

    private func filter(text: String) -> String {
        return text.filter { DictionaryManager.allowedMorseChars.map({Character($0)}).contains($0) }
    }
}

// MARK: - Setup constraints
extension MorseToTextViewController {
    private func setupConstraints() {
        view.addSubview(inputMorseCodeTextView)
        view.addSubview(topStackView)

        topStackView.addArrangedSubview(resultTextView)
        topStackView.addArrangedSubview(inputMorseCodeTextView)

        topStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(16)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-GlobalConstants.padding)
        }
    }
}

// MARK: - UITextViewDelegate
extension MorseToTextViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        var morseCode = textView.text ?? ""
        guard !isFromConstants(text: morseCode) else { return }
        morseCode = filter(text: morseCode)
        textView.text = morseCode
        let text = convertMorseCodeToText(morseCode)
        let attributedString = getDefaultTextViewAttributes(for: text)
        resultTextView.attributedText = attributedString
        UIView.animate(withDuration: 0.5) {
            self.resultTextView.isHidden = text.isEmpty
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == self.inputMorseCodeTextView {
            textView.textColor = .label
            if isFromConstants(text: textView.text ?? "") {
                textView.text.removeAll()
            }
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = Constants.insertMorseCode
        }
    }
}

fileprivate extension Dictionary where Value: Hashable {
    func swapKeyValues() -> [Value : Key] {
        var dict = Dictionary<Value, Key>()
        for (key, value) in self {
            if dict.contains(where: { dictKey, dictValue in
                dictKey == value
            }) {
                print("dict[\(value)] contains duplicate key: \"\(key)\"")
            } else {
                dict[value] = key
            }
        }
        return dict
    }
}
