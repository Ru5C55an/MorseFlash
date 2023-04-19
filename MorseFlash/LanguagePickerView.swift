//
//  LanguagePickerView.swift
//  MorseFlash
//
//  Created by Руслан Садыков on 02.04.2023.
//

import Speech
import UIKit

final class LanguagePickerViewController: UIViewController {
    enum Constants {
        static let topLineHeight: CGFloat = 6
        static let titleText = "selectLanguage".localized
    }

    private lazy var topLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = Constants.topLineHeight / 2
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.titleText
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    private let blurEffect = UIBlurEffect(style: .systemThinMaterial)
    private lazy var blurEffectView = UIVisualEffectView(effect: blurEffect)

    private let languagePicker = UIPickerView()
    private var closeButton: UIButton!
    private var selectedLocale: Locale? {
        didSet {
            onLocaleSelected?(selectedLocale)
        }
    }
    var onLocaleSelected: ((Locale?) -> Void)?
    private let locales = Array(SFSpeechRecognizer.supportedLocales()).sorted(by: { $0.identifier < $1.identifier })

    init(selectedLocale: Locale?) {
        super.init(nibName: nil, bundle: nil)
        self.selectedLocale = selectedLocale
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup language picker
        languagePicker.dataSource = self
        languagePicker.delegate = self

        // Setup close button
        closeButton = UIButton(type: .close)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        // Add subviews
        blurEffectView.contentView.addSubview(closeButton)
        blurEffectView.contentView.addSubview(languagePicker)
        blurEffectView.contentView.addSubview(topLineView)
        blurEffectView.contentView.addSubview(titleLabel)

        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)

        languagePicker.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-view.safeAreaInsets.bottom)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
        }

        topLineView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.width.equalTo(64)
            make.centerX.equalToSuperview()
            make.height.equalTo(6)
        }

        closeButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-24)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton.snp.centerY)
            make.left.equalToSuperview().inset(24)
            make.right.equalTo(closeButton.snp.left).offset(-24)
        }

        if let selectedLocale = selectedLocale,
           let selectedLocaleIndex = locales.firstIndex(of: selectedLocale) ??
            locales.firstIndex(where: { $0.identifier.prefix(2) == selectedLocale.identifier.prefix(2) }) {
                languagePicker.selectRow(selectedLocaleIndex, inComponent: 0, animated: false)
        }
    }

    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIPickerViewDataSource
extension LanguagePickerViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return locales.count
    }
}

// MARK: - UIPickerViewDelegate
extension LanguagePickerViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let localeIdentifier = locales[row].identifier
        let displayName = Locale.current.localizedString(forIdentifier: localeIdentifier) ?? localeIdentifier
        return displayName
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedLocale = locales[row]
    }
}
