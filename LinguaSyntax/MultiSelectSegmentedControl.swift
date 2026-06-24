//
//  MultiSelectSegmentedControl.swift
//  LinguaSyntax
//
//  Created by Jeremy Buchman on 6/24/26.
//

import UIKit

final class MultiSelectSegmentedControl: UIControl {
    struct Segment {
        let title: String
        let attributes: [NSAttributedString.Key: Any]
    }

    var selectedIndexes: Set<Int> = [] {
        didSet {
            updateSelectionState()
        }
    }

    private let stackView = UIStackView()
    private var buttons: [UIButton] = []

    init(segments: [Segment]) {
        super.init(frame: .zero)
        configure(segments: segments)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(segments: [Segment]) {
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 1
        backgroundColor = .tertiarySystemFill

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        buttons = segments.enumerated().map { index, segment in
            let button = UIButton(type: .system)
            button.tag = index
            button.backgroundColor = .secondarySystemGroupedBackground
            button.setAttributedTitle(NSAttributedString(string: segment.title, attributes: segment.attributes), for: .normal)
            button.setAttributedTitle(NSAttributedString(string: segment.title, attributes: selectedAttributes(from: segment.attributes)), for: .selected)
            button.addAction(UIAction { [weak self] _ in
                self?.toggleSegment(at: index)
            }, for: .touchUpInside)
            button.accessibilityLabel = segment.title
            return button
        }

        buttons.forEach(stackView.addArrangedSubview)
        updateSelectionState()
    }

    private func toggleSegment(at index: Int) {
        if selectedIndexes.contains(index) {
            selectedIndexes.remove(index)
        } else {
            selectedIndexes.insert(index)
        }

        sendActions(for: .valueChanged)
    }

    private func updateSelectionState() {
        for button in buttons {
            let isSelected = selectedIndexes.contains(button.tag)
            button.isSelected = isSelected
            button.backgroundColor = isSelected ? tintColor : .secondarySystemGroupedBackground
        }
    }

    private func selectedAttributes(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var selectedAttributes = attributes
        selectedAttributes[.foregroundColor] = UIColor.white
        return selectedAttributes
    }
}
