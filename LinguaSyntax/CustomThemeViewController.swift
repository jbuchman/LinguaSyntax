//
//  CustomThemeViewController.swift
//  LinguaSyntax
//
//  Created by Jeremy Buchman on 6/24/26.
//

import NaturalLanguage
import UIKit

final class CustomThemeViewController: UIViewController, UIColorPickerViewControllerDelegate {
    private enum ColorTarget {
        case background
        case tag(NLTag)
    }

    private var draft: CustomTheme
    private let onSave: (CustomTheme) -> Void
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var colorTarget: ColorTarget?

    init(theme: CustomTheme, onSave: @escaping (CustomTheme) -> Void) {
        draft = theme
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(localized: "Custom Theme")
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            onSave(draft)
            dismiss(animated: true)
        })

        configureLayout()
        rebuildContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyInterfaceStyle()
    }

    private func configureLayout() {
        applyInterfaceStyle()
        view.backgroundColor = .systemBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 24, trailing: 20)
        stackView.isLayoutMarginsRelativeArrangement = true

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func rebuildContent() {
        applyInterfaceStyle()
        view.backgroundColor = .systemBackground

        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        stackView.addArrangedSubview(makeInterfaceStyleSection())
        stackView.addArrangedSubview(makeColorRow(title: String(localized: "Background"), color: draft.backgroundColor.uiColor, target: .background))
        stackView.addArrangedSubview(makeSectionHeader(String(localized: "Parts of Speech")))

        for tag in CustomTheme.editableTags {
            stackView.addArrangedSubview(makeTagRow(tag: tag))
        }
    }

    private func applyInterfaceStyle() {
        let interfaceStyle = draft.interfaceStyle.uiUserInterfaceStyle
        overrideUserInterfaceStyle = interfaceStyle
        navigationController?.overrideUserInterfaceStyle = interfaceStyle
        navigationController?.navigationBar.tintColor = .label

        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.backgroundColor = .systemBackground
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        navigationController?.navigationBar.standardAppearance = navigationBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController?.navigationBar.compactAppearance = navigationBarAppearance
    }

    private func makeInterfaceStyleSection() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let label = makeSectionHeader(String(localized: "Base Interface Style"))
        let segmentedControl = UISegmentedControl(items: [
            String(localized: "Light"),
            String(localized: "Dark")
        ])
        segmentedControl.selectedSegmentIndex = draft.interfaceStyle == .light ? 0 : 1
        segmentedControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            draft.interfaceStyle = segmentedControl.selectedSegmentIndex == 0 ? .light : .dark
            rebuildContent()
        }, for: .valueChanged)

        container.addArrangedSubview(label)
        container.addArrangedSubview(segmentedControl)
        return container
    }

    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func makeTagRow(tag: NLTag) -> UIView {
        let style = draft.style(for: tag)
        let row = UIStackView()
        row.axis = .vertical
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)

        row.addArrangedSubview(makeColorRow(title: tag.localizedName, color: style.color.uiColor, target: .tag(tag)))

        let controls = makeStyleControl(for: tag, style: style)

        row.addArrangedSubview(controls)
        return row
    }

    private func makeColorRow(title: String, color: UIColor, target: ColorTarget) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = color
        button.layer.cornerRadius = 8
        button.layer.borderColor = UIColor.separator.cgColor
        button.layer.borderWidth = 1
        button.accessibilityLabel = String(localized: "Choose \(title) color")
        button.addAction(UIAction { [weak self] _ in
            self?.presentColorPicker(for: target, color: color)
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])

        row.addArrangedSubview(label)
        row.addArrangedSubview(button)
        return row
    }

    private func makeStyleControl(for tag: NLTag, style: CustomTagStyle) -> MultiSelectSegmentedControl {
        let control = MultiSelectSegmentedControl(segments: [
            MultiSelectSegmentedControl.Segment(title: String(localized: "Bold"), attributes: styleTitleAttributes(isBold: true)),
            MultiSelectSegmentedControl.Segment(title: String(localized: "Italic"), attributes: styleTitleAttributes(isItalic: true)),
            MultiSelectSegmentedControl.Segment(title: String(localized: "Underline"), attributes: styleTitleAttributes(isUnderlined: true))
        ])
        var selectedIndexes = Set<Int>()
        if style.isBold {
            selectedIndexes.insert(0)
        }
        if style.isItalic {
            selectedIndexes.insert(1)
        }
        if style.isUnderlined {
            selectedIndexes.insert(2)
        }
        control.selectedIndexes = selectedIndexes
        control.addAction(UIAction { [weak self, weak control] _ in
            guard let self, let control else { return }
            updateStyle(for: tag, shouldRebuild: false) { style in
                style.isBold = control.selectedIndexes.contains(0)
                style.isItalic = control.selectedIndexes.contains(1)
                style.isUnderlined = control.selectedIndexes.contains(2)
            }
        }, for: .valueChanged)
        return control
    }

    private func styleTitleAttributes(
        isBold: Bool = false,
        isItalic: Bool = false,
        isUnderlined: Bool = false
    ) -> [NSAttributedString.Key: Any] {
        var font = UIFont.preferredFont(forTextStyle: .body)
        if isBold {
            font = font.bold()
        }
        if isItalic {
            font = font.italic()
        }

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]
        if isUnderlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        return attributes
    }

    private func presentColorPicker(for target: ColorTarget, color: UIColor) {
        colorTarget = target
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = color
        colorPicker.supportsAlpha = false
        present(colorPicker, animated: true)
    }

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        updateColor(viewController.selectedColor)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        updateColor(viewController.selectedColor)
    }

    private func updateColor(_ color: UIColor) {
        guard let colorTarget else { return }

        switch colorTarget {
        case .background:
            draft.backgroundColor = ThemeColor(color: color)
        case .tag(let tag):
            updateStyle(for: tag, shouldRebuild: false) { style in
                style.color = ThemeColor(color: color)
            }
        }

        rebuildContent()
    }

    private func updateStyle(for tag: NLTag, shouldRebuild: Bool = true, _ update: (inout CustomTagStyle) -> Void) {
        var style = draft.style(for: tag)
        update(&style)
        draft.tagStyles[tag.rawValue] = style

        if shouldRebuild {
            rebuildContent()
        }
    }
}
