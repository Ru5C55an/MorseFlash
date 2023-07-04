//
//  ViewController.swift
//  MorseFlash
//
//  Created by Руслан Садыков on 31.03.2023.
//

import UIKit
import AVFoundation
import SnapKit
import Speech
import FittedSheets
import AlertKit

final class TextToMorseViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let recordButtonSize: CGFloat = 64.0
        static let tapToStartText = "tapToStartText".localized
        static let needEnableAccessToSpeechRecognitionText = "needEnableAccessToSpeechRecognitionText".localized
        static let speakText = "speakText".localized
        static let cancelPlayingText = "cancelPlayingText".localized
        static let startPlayingText = "startPlayingText".localized
        static let noTextForPlaying = "noTextForPlaying".localized
        static let errorAccessCamera = "errorAccessCamera".localized
        static let errorTurnOnFlashlight = "errorTurnOnFlashlight".localized
        static let errorTurnOffFlashlight = "errorTurnOffFlashlight".localized
        static let deniedSpeechRecognition = "deniedSpeechRecognition".localized
        static let restrictedSpeechRecognition = "restrictedSpeechRecognition".localized
        static let notRecognisedSpeechRecognition = "notRecognisedSpeechRecognition".localized
        static let alertPresentDuration: TimeInterval = 4
    }

    // MARK: - UI Elements
    private let topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 20
        stackView.distribution = .equalSpacing
        stackView.axis = .vertical
        return stackView
    }()

    private let morseCodeTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isHidden = true
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
        return textView
    }()

    private let flashlightButton: UIButton = {
        let button = UIButton(configuration: .borderedTinted())
        button.setTitle(Constants.startPlayingText, for: .normal)
        button.setTitle(Constants.noTextForPlaying, for: .disabled)
        button.isEnabled = false
        button.layer.cornerRadius = 10.0
        button.addTarget(
            self,
            action: #selector(flashlightButtonTapped(_:)),
            for: .touchUpInside
        )
        button.tintColor = .systemGreen
        return button
    }()

    private lazy var recordButton: UIButton = {
        // Создаем конфигурацию символа
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let button = UIButton(configuration: .tinted())
        button.setImage(UIImage(
            systemName: "mic.fill",
            withConfiguration: symbolConfig
        ), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(
            self,
            action: #selector(recordButtonTapped),
            for: .touchUpInside
        )
        return button
    }()

    private lazy var infoBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "info.circle"),
        style: .plain,
        target: self,
        action: #selector(infoBarButtonDidTap)
    )

    // MARK: - Properties
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isFlashing = false
    private var isRecording: Bool = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "textInMorseCode".localized
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

        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            print("SFSpeechRecognizer Auth status: ", authStatus)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem = infoBarButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaults.standard.isNeedTutorial != false {
            showInfo()
        }
    }

    // MARK: - Handlers
    @objc private func showLanguagePicker() {
        stopRecording()
        stopFlashlight()
        DictionaryManager.shared.showLanguagePicker(from: self) {
            guard self.speechRecognizer?.locale != DictionaryManager.shared.locale else {
                return
            }
            self.speechRecognizer = SFSpeechRecognizer(locale: DictionaryManager.shared.locale)
            self.textView.text.removeAll()
            self.textView.delegate?.textViewDidChange?(self.textView)
        }
    }

    @objc private func flashlightButtonTapped(_ sender: UIButton) {
        if isFlashing {
            stopFlashlight()
        } else {
            playFlashlight()
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

    // Функция для обработки нажатия на кнопку записи голоса
    @objc private func recordButtonTapped() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization({ [weak self] authStatus in
                switch authStatus {
                case .notDetermined:
                    self?.showNotAuthorizedSpeechRecognitionError()
                    return
                case .denied:
                    self?.showSpeechRecognitionDeniedError()
                    return
                case .restricted:
                    self?.showRestrictedSpeechRecognitionError()
                    return
                case .authorized:
                    break
                @unknown default:
                    return
                }
            })
        case .denied:
            showSpeechRecognitionDeniedError()
            return
        case .restricted:
            showRestrictedSpeechRecognitionError()
            return
        case .authorized:
            break
        @unknown default:
            return
        }

        if audioEngine.isRunning {
            stopRecording()
        } else {
            recordButton.tintColor = .systemOrange
            textView.text = Constants.speakText
            startRecording()
            animateRecordButton(true)
        }
    }

    @objc private func openMorseToTextVC() {
        let vc = MorseToTextViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func infoBarButtonDidTap() {
        showInfo()
    }

    // MARK: - Functions
    private func playFlashlight() {
        guard let flashlight = AVCaptureDevice.default(for: .video) else {
            print(Constants.errorAccessCamera)
            return
        }
        stopRecording()
        let morseCode = morseCodeTextView.text ?? ""
        let unitDuration = 0.3 // длительность каждой единицы кода Морзе в секундах
        isFlashing = true
        flashlightButton.tintColor = .systemOrange
        flashlightButton.setTitle(Constants.cancelPlayingText, for: .normal)
        let queue = DispatchQueue(label: "morseCodeQueue", qos: .userInteractive)
        queue.async {
            for (index, char) in morseCode.enumerated() {
                guard self.isFlashing else {
                    DispatchQueue.main.async {
                        self.stopFlashlight()
                    }
                    return
                }
                switch char {
                case ".":
                    do {
                        try flashlight.lockForConfiguration()
                        flashlight.torchMode = .on
                        Thread.sleep(forTimeInterval: unitDuration)
                        flashlight.torchMode = .off
                        flashlight.unlockForConfiguration()
                        Thread.sleep(forTimeInterval: unitDuration)
                    } catch {
                        print(Constants.errorTurnOffFlashlight)
                    }
                case "-":
                    do {
                        try flashlight.lockForConfiguration()
                        flashlight.torchMode = .on
                        Thread.sleep(forTimeInterval: 3 * unitDuration)
                        flashlight.torchMode = .off
                        flashlight.unlockForConfiguration()
                        Thread.sleep(forTimeInterval: unitDuration)
                    } catch {
                        print(Constants.errorTurnOnFlashlight)
                    }
                case " ":
                    Thread.sleep(forTimeInterval: 3 * unitDuration)
                default:
                    continue
                }
                // выделяем уже воспроизведенную часть зеленым цветом
                DispatchQueue.main.async {
                    self.makeHighlitedText(with: index, for: morseCode)
                }
            }
        }
    }

    private func stopFlashlight() {
        isFlashing = false
        flashlightButton.tintColor = .systemGreen
        flashlightButton.setTitle(Constants.startPlayingText, for: .normal)
        let morseCode = morseCodeTextView.attributedText.string
        let attributedString = getDefaultTextViewAttributes(for: morseCode)
        morseCodeTextView.attributedText = attributedString
    }

    private func makeHighlitedText(with index: Int, for morseCode: String) {
        let highlightRange = NSRange(location: 0, length: index+1)
        let attributedString = getDefaultTextViewAttributes(for: morseCode)
        attributedString.addAttributes([
            .foregroundColor: UIColor.systemOrange,
            .font: GlobalConstants.morseTextViewFont,
        ], range: highlightRange)
        morseCodeTextView.attributedText = attributedString
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

    private func showSpeechRecognitionDeniedError() {
        let alertView = AlertKit.AlertAppleMusic16View(
            title: Constants.deniedSpeechRecognition,
            subtitle: nil,
            icon: .error
        )
        alertView.duration = Constants.alertPresentDuration
        alertView.present(on: self.view)
        textView.text = Constants.needEnableAccessToSpeechRecognitionText
        textView.textColor = .systemOrange
    }

    private func showNotAuthorizedSpeechRecognitionError() {
        let alertView = AlertKit.AlertAppleMusic16View(
            title: Constants.notRecognisedSpeechRecognition,
            subtitle: nil,
            icon: .error
        )
        alertView.duration = Constants.alertPresentDuration
        alertView.present(on: self.view)
    }

    private func showRestrictedSpeechRecognitionError() {
        let alertView = AlertKit.AlertAppleMusic16View(
            title: Constants.restrictedSpeechRecognition,
            subtitle: nil,
            icon: .error
        )
        alertView.duration = Constants.alertPresentDuration
        alertView.present(on: self.view)
        textView.text = Constants.needEnableAccessToSpeechRecognitionText
        textView.textColor = .systemOrange
    }

    func animateRecordButton(_ isRecording: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .autoreverse, .repeat], animations: {
            if isRecording {
                self.recordButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                self.recordButton.transform = CGAffineTransform.identity
                self.recordButton.layer.removeAllAnimations()
            }
        }, completion: nil)
    }

    private func stopRecording() {
        // Проверяем, что запись активна
        guard isRecording else { return }

        // Устанавливаем флаг isRecording в false
        isRecording = false

        // Изменяем внешний вид кнопки на "готовность к записи"
        recordButton.setBackgroundImage(UIImage(systemName: "mic.fill"), for: .normal)

        recordButton.tintColor = .systemBlue
        recordButton.isEnabled = false
        if textView.text.isEmpty {
            textView.text = Constants.tapToStartText
        }
        animateRecordButton(false)

        audioEngine.stop()
        recognitionRequest?.endAudio()
    }

    // Функция для начала записи голоса
    private func startRecording() {
        // Проверяем, что запись не активна
        guard !isRecording else { return }
        stopFlashlight()

        // Устанавливаем флаг isRecording в true
        isRecording = true

        // Изменяем внешний вид кнопки на "запись в процессе"
        recordButton.setBackgroundImage(UIImage(systemName: "mic.fill"), for: .normal)

        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Ошибка установки категории записи и активации аудиосессии: \(error)")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Невозможно создать экземпляр объекта SFSpeechAudioBufferRecognitionRequest")
        }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { result, error in
            var isFinal = false

            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
                self.textViewDidChange(self.textView)
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.recordButton.isEnabled = true
                self.recordButton.setImage(UIImage(named: "record"), for: .normal)
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Ошибка запуска аудио движка: \(error)")
        }
    }

    private func convertTextToMorseCode(_ text: String) -> String {
        var morseText = ""
        for char in text.lowercased() {
            let localeDisctionary: [String: String]
            if let morseDictionary = DictionaryManager.shared.getMorseDictionary(for: DictionaryManager.shared.locale) {
                localeDisctionary = morseDictionary
            } else {
                return GlobalConstants.unsupportedLocale
            }
            switch char {
            case let x where DictionaryManager.morseCodeDigits.keys.contains(String(x)):
                morseText += DictionaryManager.morseCodeDigits[String(x)]! + " "
            case let x where localeDisctionary.keys.contains(String(x)):
                morseText += localeDisctionary[String(x)]! + " "
            case let x where DictionaryManager.specialTable.keys.contains(String(x)):
                morseText += DictionaryManager.specialTable[String(x)]! + " "
            default:
                continue
            }
        }

        return morseText.trimmingCharacters(in: .whitespaces)
    }

    private func isFromConstants(text: String) -> Bool {
        if text == Constants.tapToStartText ||
            text == Constants.speakText ||
            text == Constants.needEnableAccessToSpeechRecognitionText {
            return true
        } else {
            return false
        }
    }

    private func filter(text: String) -> String {
        var allowedCharacters = (Array(DictionaryManager.morseCodeDigits.keys)) + (Array(DictionaryManager.specialTable.keys))
        if let localeDictionary = DictionaryManager.shared.getMorseDictionary(for: DictionaryManager.shared.locale) {
            allowedCharacters += Array(localeDictionary.keys)
        }
        allowedCharacters = allowedCharacters.map({ $0 })
        return text.filter { character in
            if allowedCharacters.contains(where: { $0 == character.lowercased() }) {
                return true
            } else {
                AlertKitAPI.present(
                    title: String(
                        format: NSLocalizedString("unavailableCharacter", comment: ""),
                        "\(character)"
                    ),
                    subtitle: "needChangeLanguageInApp".localized,
                    icon: .custom(UIImage(systemName: "exclamationmark.circle")!),
                    style: .iOS16AppleMusic,
                    haptic: .warning
                )
                return false
            }
        }
    }

    private func showInfo() {
        let alertView = AlertKit.AlertAppleMusic16View(
            title: "selectLanguage".localized ,
            subtitle: "availableCharacters".localized,
            icon: .custom(UIImage(systemName: "info.bubble")!)
        )
        alertView.dismissByTap = true
        alertView.dismissInTime = false
        alertView.present(on: self.view) {
            UserDefaults.standard.isNeedTutorial = false
        }
    }
}

// MARK: - Setup constraints
extension TextToMorseViewController {
    private func setupConstraints() {
        view.addSubview(recordButton)
        view.addSubview(textView)
        view.addSubview(topStackView)

        topStackView.addArrangedSubview(morseCodeTextView)
        topStackView.addArrangedSubview(flashlightButton)

        topStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.left.right.equalToSuperview().inset(GlobalConstants.padding)
        }

        morseCodeTextView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(64)
        }

        flashlightButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }

        textView.snp.makeConstraints { make in
            make.top.equalTo(flashlightButton.snp.bottom).offset(GlobalConstants.padding)
            make.left.right.equalToSuperview().inset(GlobalConstants.padding)
            make.height.greaterThanOrEqualTo(100)
            make.bottom.equalTo(recordButton.snp.top).offset(-GlobalConstants.padding)
        }

        recordButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-GlobalConstants.padding)
            make.width.height.equalTo(Constants.recordButtonSize)
        }
    }
}

// MARK: - UITextViewDelegate
extension TextToMorseViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        var text = textView.text ?? ""
        guard !isFromConstants(text: text) else { return }
        text = filter(text: text)
        textView.text = text
        let morseCode = convertTextToMorseCode(text)
        let attributedString = getDefaultTextViewAttributes(for: morseCode)
        morseCodeTextView.attributedText = attributedString
        flashlightButton.isEnabled = !morseCode.isEmpty
        morseCodeTextView.isHidden = morseCode.isEmpty
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == self.textView {
            textView.textColor = .label
            if isFromConstants(text: textView.text ?? "") {
                textView.text.removeAll()
            }
            stopRecording()
        }
    }
}
