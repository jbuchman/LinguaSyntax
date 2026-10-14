//
//  ViewController.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import Combine
import NaturalLanguage

class ViewController: UIViewController {
    @IBOutlet weak var textView: TextView! { didSet {
        textView.delegate = self
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
    }}
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderTrailingConstraint: NSLayoutConstraint!
    let settings = Settings()
    var cancellables: Set<AnyCancellable> = []
    private var keyboardOverlapHeight: CGFloat = 0
    private var isKeyboardVisible = false
    private var textViewBaseContentInset: UIEdgeInsets?
    private var textViewBaseBottomConstraintConstant: CGFloat?
    private var requestedLexicalAssetLanguages = Set<NLLanguage>()
    private lazy var counterSheetSourceView = makeCounterSheetSourceView()

    lazy var counterViewController: CounterViewController? = {
        storyboard?.instantiateViewController(identifier: "counter") { coder in
            CounterViewController(coder: coder, settings: self.settings, sourceTextView: self.textView)
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 26.0, *) {
            configureCornerAdaptedTextLayout()
        }
        
        configureCounterSheetSourceView()
        navigationController?.navigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resetFocus)))
        
        settings.$text.receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] text in
            guard let self else {
                return
            }

            guard self.textView.text != text else {
                return
            }

            self.textView.text = text
            self.updateSyntaxHighlight()
        }).store(in: &cancellables)
        
        settings.$theme.receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] theme in
            guard let self else {
                return
            }

            self.updateSyntaxHighlight(theme: theme)
        }).store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.keyboardFrameWillChange(notification)
            }
            .store(in: &cancellables)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let counterViewController = counterViewController, presentedViewController == nil else { return }
        
        // 1. Configure the View Controller layout parameters PRIOR to presentation
        counterViewController.modalPresentationStyle = .pageSheet
        counterViewController.preferredContentSize = CGSize(
            width: Self.preferredCounterSheetWidth(containerWidth: view.bounds.width),
            height: 0
        )
        counterViewController.isModalInPresentation = true // CRITICAL FIX: Blocks pull-down dismiss gestures!
        
        configureCounterSheet(selectedDetentIdentifier: Constants.minimizedIdentifier)

        present(counterViewController, animated: true) { [weak self] in
            self?.updateTextViewLayoutForCounterOverlap()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { [weak self] _ in
            self?.configureCounterSheet(
                animated: true,
                selectedDetentIdentifier: Constants.minimizedIdentifier
            )
        } completion: { [weak self] _ in
            self?.updateTextViewLayoutForCounterOverlap()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateTextViewLayoutForCounterOverlap()
    }

    func windowSceneGeometryDidUpdate() {
        view.layoutIfNeeded()
        configureCounterSheet(selectedDetentIdentifier: Constants.minimizedIdentifier)
        updateTextViewLayoutForCounterOverlap()

        DispatchQueue.main.async { [weak self] in
            self?.configureCounterSheet(selectedDetentIdentifier: Constants.minimizedIdentifier)
            self?.updateTextViewLayoutForCounterOverlap()
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        textView.canPerformAction(action, withSender: sender)
    }
    
    @objc func resetFocus() {
        textView.resignFirstResponder()
    }

    private func configureCounterSheetSourceView() {
        view.addSubview(counterSheetSourceView)

        NSLayoutConstraint.activate([
            counterSheetSourceView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            counterSheetSourceView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            counterSheetSourceView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            counterSheetSourceView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    @available(iOS 26.0, *)
    private func configureCornerAdaptedTextLayout() {
        NSLayoutConstraint.deactivate([
            textViewLeadingConstraint,
            textViewTrailingConstraint,
            placeholderLeadingConstraint,
            placeholderTrailingConstraint
        ])

        let safeArea = view.layoutGuide(for: .safeArea(cornerAdaptation: .horizontal))
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            placeholderLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16)
        ])
    }

    private func makeCounterSheetSourceView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }
    
    private func updateSyntaxHighlight(theme: Theme? = nil) {
        let theme = theme ?? settings.theme
        if !textView.isFirstResponder, textView.text.isEmpty, let string = placeholderLabel.text {
            placeholderLabel.attributedText = NSAttributedString(string: string, attributes: [
                .font: theme.font,
                .foregroundColor: UIColor.secondaryLabel
            ])
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
            applySyntaxHighlight(theme: theme)
        }
        view.backgroundColor = theme.backgroundColor
        overrideUserInterfaceStyle = theme.interfaceStyle
        textView.overrideUserInterfaceStyle = theme.interfaceStyle
        navigationController?.navigationBar.overrideUserInterfaceStyle = theme.interfaceStyle
        counterViewController?.overrideUserInterfaceStyle = theme.interfaceStyle
    }

    private func applySyntaxHighlight(theme: Theme) {
        textView.typingAttributes = Theme.textAttributes(theme: theme)

        guard textView.markedTextRange == nil else {
            return
        }

        let string = textView.text ?? ""
        guard !string.isEmpty else {
            return
        }

        let language = string.syntaxLanguage(fallback: textView.textInputMode?.naturalLanguageHint)
        requestLexicalAssetsIfNeeded(for: language)

        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        textView.textStorage.beginEditing()
        textView.textStorage.removeAttribute(.underlineStyle, range: fullRange)
        textView.textStorage.addAttributes(Theme.textAttributes(theme: theme), range: fullRange)

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = string
        tagger.setLanguageHint(textView.textInputMode?.naturalLanguageHint, for: string)
        tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .lexicalClass, options: String.syntaxTaggerOptions) { tag, tokenRange in
            guard let tag else {
                return true
            }
            textView.textStorage.addAttributes(tag.textAttributes(theme: theme), range: NSRange(tokenRange, in: string))
            return true
        }

        textView.textStorage.endEditing()
    }

    private func requestLexicalAssetsIfNeeded(for language: NLLanguage?) {
        guard let language,
              !NLTagger.availableTagSchemes(for: .word, language: language).contains(.lexicalClass),
              requestedLexicalAssetLanguages.insert(language).inserted else {
            return
        }

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let result = try await NLTagger.requestAssets(for: language, tagScheme: .lexicalClass)
                if result == .available {
                    self.updateSyntaxHighlight()
                } else {
                    self.requestedLexicalAssetLanguages.remove(language)
                }
            } catch {
                self.requestedLexicalAssetLanguages.remove(language)
            }
        }
    }

    private func keyboardFrameWillChange(_ notification: Notification) {
        keyboardOverlapHeight = keyboardOverlap(from: notification)
        isKeyboardVisible = keyboardIsVisible(from: notification)
        counterViewController?.setKeyboardDismissButtonVisible(isKeyboardVisible)
        configureCounterSheet(
            animated: notification.name != UIResponder.keyboardDidHideNotification,
            selectedDetentIdentifier: Constants.minimizedIdentifier
        )
    }

    private func keyboardOverlap(from notification: Notification) -> CGFloat {
        guard notification.name != UIResponder.keyboardWillHideNotification,
              notification.name != UIResponder.keyboardDidHideNotification,
              let keyboardFrameInView = keyboardFrameInView(from: notification) else {
            return 0
        }

        let intersection = view.bounds.intersection(keyboardFrameInView)
        guard !intersection.isNull else {
            return 0
        }

        return max(0, view.bounds.maxY - intersection.minY)
    }

    private func keyboardIsVisible(from notification: Notification) -> Bool {
        guard notification.name != UIResponder.keyboardWillHideNotification,
              notification.name != UIResponder.keyboardDidHideNotification,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return false
        }

        let screenBounds = (notification.object as? UIScreen ?? view.window?.screen)?.bounds ?? UIScreen.main.bounds
        return Self.keyboardIsVisible(keyboardFrame: keyboardFrame, screenBounds: screenBounds)
    }

    private func keyboardFrameInView(from notification: Notification) -> CGRect? {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let coordinateSpace = (notification.object as? UIScreen ?? view.window?.screen)?.coordinateSpace else {
            return nil
        }

        return coordinateSpace.convert(keyboardFrame, to: view)
    }

    private func configureCounterSheet(
        animated: Bool = false,
        selectedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = nil
    ) {
        guard let sheet = counterViewController?.sheetPresentationController else {
            return
        }

        let updateSheet = {
            self.counterViewController?.preferredContentSize = CGSize(
                width: Self.preferredCounterSheetWidth(containerWidth: self.view.bounds.width),
                height: 0
            )
            sheet.delegate = self
            sheet.detents = self.counterSheetDetents()
            sheet.invalidateDetents()
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            sheet.sourceView = self.counterSheetSourceView
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            if let selectedDetentIdentifier {
                sheet.selectedDetentIdentifier = selectedDetentIdentifier
                if self.counterViewController?.isViewLoaded == true {
                    self.counterViewController?.updateAppearance(isMinimized: selectedDetentIdentifier == Constants.minimizedIdentifier)
                }
            }
            self.updateTextViewLayoutForCounterOverlap()
        }

        if animated {
            sheet.animateChanges(updateSheet)
        } else {
            updateSheet()
        }
    }

    private func counterSheetDetents() -> [UISheetPresentationController.Detent] {
        Self.counterSheetDetentIdentifiers(
            isKeyboardVisible: isKeyboardVisible,
            isCompactHeight: traitCollection.verticalSizeClass == .compact
        ).map { identifier in
            switch identifier {
            case Constants.minimizedIdentifier:
                return minimizedDetent()
            case Constants.keyboardTextViewHalfIdentifier:
                return keyboardTextViewHalfDetent()
            case Constants.compactTextViewHalfIdentifier:
                return compactTextViewHalfDetent()
            case .medium:
                return .medium()
            default:
                return .large()
            }
        }
    }

    static func counterSheetDetentIdentifiers(
        isKeyboardVisible: Bool,
        isCompactHeight: Bool = false
    ) -> [UISheetPresentationController.Detent.Identifier] {
        if isKeyboardVisible {
            return [Constants.minimizedIdentifier, Constants.keyboardTextViewHalfIdentifier, .large]
        }

        if isCompactHeight {
            return [Constants.minimizedIdentifier, Constants.compactTextViewHalfIdentifier, .large]
        }

        return [Constants.minimizedIdentifier, .medium, .large]
    }

    static func preferredCounterSheetWidth(containerWidth: CGFloat) -> CGFloat {
        min(max(containerWidth * 0.6, 360), 480)
    }

    static func keyboardIsVisible(keyboardFrame: CGRect, screenBounds: CGRect) -> Bool {
        keyboardFrame.height > 0 && keyboardFrame.minY < screenBounds.maxY
    }

    private func updateTextViewLayoutForCounterOverlap() {
        guard isViewLoaded,
              textView != nil,
              textViewBottomConstraint != nil else {
            return
        }

        if textViewBaseContentInset == nil {
            textViewBaseContentInset = textView.contentInset
        }
        if textViewBaseBottomConstraintConstant == nil {
            textViewBaseBottomConstraintConstant = textViewBottomConstraint.constant
        }

        let baseBottomConstraintConstant = textViewBaseBottomConstraintConstant ?? 0
        let counterFrame = counterFrameInView()
        let bottomConstraintConstant = Self.textViewBottomConstraintConstant(
            baseConstant: baseBottomConstraintConstant,
            safeAreaFrame: view.safeAreaLayoutGuide.layoutFrame,
            counterFrame: counterFrame,
            clearance: Constants.counterSheetTextViewClearance
        )

        if textViewBottomConstraint.constant != bottomConstraintConstant {
            textViewBottomConstraint.constant = bottomConstraintConstant
            view.layoutIfNeeded()
        }

        var contentInset = textViewBaseContentInset ?? .zero
        contentInset.bottom = Self.counterOverlapHeight(
            textViewFrame: textView.frame,
            counterFrame: counterFrame
        )

        guard textView.contentInset != contentInset else {
            return
        }

        textView.contentInset = contentInset
        textView.scrollIndicatorInsets = contentInset
    }

    private func counterFrameInView() -> CGRect {
        let minimizedFrame = minimizedCounterFrameInView()

        if let presentationController = counterViewController?.presentationController,
           let containerView = presentationController.containerView {
            let presentedFrame = view.convert(presentationController.frameOfPresentedViewInContainerView, from: containerView)
            guard let minimizedFrame else {
                return presentedFrame
            }

            return presentedFrame.isNull || presentedFrame.minY > minimizedFrame.minY
                ? minimizedFrame
                : presentedFrame
        }

        guard let counterView = counterViewController?.viewIfLoaded,
              counterView.window != nil else {
            return minimizedFrame ?? .null
        }

        let counterFrame = view.convert(counterView.bounds, from: counterView)
        guard let minimizedFrame else {
            return counterFrame
        }

        return counterFrame.isNull || counterFrame.minY > minimizedFrame.minY
            ? minimizedFrame
            : counterFrame
    }

    private func minimizedCounterFrameInView() -> CGRect? {
        guard counterViewController?.sheetPresentationController?.selectedDetentIdentifier == Constants.minimizedIdentifier else {
            return nil
        }

        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame
        let visibleHeight = isKeyboardVisible
            ? Constants.keyboardMinimizedDetentVisibleHeight
            : Constants.minimizedDetentHeight
        let height = visibleHeight + keyboardOverlapHeight
        return CGRect(
            x: safeAreaFrame.minX,
            y: safeAreaFrame.maxY - height,
            width: safeAreaFrame.width,
            height: height
        )
    }

    static func counterOverlapHeight(textViewFrame: CGRect, counterFrame: CGRect) -> CGFloat {
        let intersection = textViewFrame.intersection(counterFrame)
        guard !intersection.isNull else {
            return 0
        }

        return intersection.height
    }

    static func textViewBottomConstraintConstant(
        baseConstant: CGFloat,
        safeAreaFrame: CGRect,
        counterFrame: CGRect,
        clearance: CGFloat = 0
    ) -> CGFloat {
        guard !counterFrame.isNull,
              counterFrame.minY < safeAreaFrame.maxY else {
            return baseConstant
        }

        return max(baseConstant, safeAreaFrame.maxY - counterFrame.minY + clearance)
    }

    private func minimizedDetent() -> UISheetPresentationController.Detent {
        UISheetPresentationController.Detent.custom(identifier: Constants.minimizedIdentifier) { [weak self] _ in
            guard let self else {
                return Constants.minimizedDetentHeight
            }

            let visibleHeight = isKeyboardVisible
                ? Constants.keyboardMinimizedDetentVisibleHeight
                : Constants.minimizedDetentHeight
            return visibleHeight + keyboardOverlapHeight
        }
    }

    private func keyboardTextViewHalfDetent() -> UISheetPresentationController.Detent {
        UISheetPresentationController.Detent.custom(identifier: Constants.keyboardTextViewHalfIdentifier) { [weak self] context in
            guard let self else {
                return context.maximumDetentValue
            }

            return Self.keyboardTextViewHalfDetentHeight(
                viewHeight: view.bounds.height,
                keyboardOverlapHeight: keyboardOverlapHeight,
                maximumDetentValue: context.maximumDetentValue
            )
        }
    }

    private func compactTextViewHalfDetent() -> UISheetPresentationController.Detent {
        UISheetPresentationController.Detent.custom(identifier: Constants.compactTextViewHalfIdentifier) { context in
            Self.compactTextViewHalfDetentHeight(maximumDetentValue: context.maximumDetentValue)
        }
    }

    static func compactTextViewHalfDetentHeight(maximumDetentValue: CGFloat) -> CGFloat {
        maximumDetentValue / 2
    }

    static func keyboardTextViewHalfDetentHeight(
        viewHeight: CGFloat,
        keyboardOverlapHeight: CGFloat,
        maximumDetentValue: CGFloat
    ) -> CGFloat {
        let availableHeightAboveKeyboard = max(0, viewHeight - keyboardOverlapHeight)
        let visibleHeight = availableHeightAboveKeyboard / 2
        let detentHeight = keyboardOverlapHeight + visibleHeight
        return min(detentHeight, maximumDetentValue)
    }
}

// MARK: - UITextViewDelegate
extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSyntaxHighlight()
        settings.text = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        updateSyntaxHighlight()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updateSyntaxHighlight()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate & UISheetPresentationControllerDelegate
extension ViewController: UIAdaptivePresentationControllerDelegate, UISheetPresentationControllerDelegate {
    
    // Fallback handler if isModalInPresentation flags face boundary constraints
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    // Enforces Apple Maps bounce-back mechanism when an illegal downward swipe occurs
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        if let sheet = counterViewController?.sheetPresentationController {
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = Constants.minimizedIdentifier
            }
        }
    }
    
    // Triggers automatically the exact instant the sheet successfully settles into a detent position
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        counterViewController?.updateAppearance()
        updateTextViewLayoutForCounterOverlap()
        DispatchQueue.main.async { [weak self] in
            self?.updateTextViewLayoutForCounterOverlap()
        }
    }
}
