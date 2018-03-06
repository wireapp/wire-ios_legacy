//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import Cartography

@objc protocol CallQualityViewControllerDelegate: class {
    func callQualityControllerDidFinishWithoutScore(_ controller: CallQualityViewController)
    func callQualityController(_ controller: CallQualityViewController, didSelect score: Int)
}

class CallQualityViewController : UIViewController, UIGestureRecognizerDelegate {
    
    @objc weak var delegate: CallQualityViewControllerDelegate?
    var contentView: UIView
    var dimmingView: UIView
    var dismissTapGestureRecognizer: UITapGestureRecognizer!

    var callQualityStackView : UICustomSpacingStackView!
    var closeButton : IconButton
    let titleLabel : UILabel
    let questionText : UILabel
    var scoreSelectorView : QualityScoreSelectorView!
    var questionLabelText = String()
    
    // MARK: Contraints
    
    private var ipad_centerXConstraint: NSLayoutConstraint!
    private var ipad_centerYConstraint: NSLayoutConstraint!
    private var iphone_leadingConstraint: NSLayoutConstraint!
    private var iphone_trailingConstraint: NSLayoutConstraint!
    private var iphone_bottomConstraint: NSLayoutConstraint!
    
    // MARK: Initialization
    
    static func defaultSurveyController() -> CallQualityViewController {
        let controller = CallQualityViewController(questionLabelText: NSLocalizedString("calling.quality_survey.question", comment: ""))
        controller.modalPresentationCapturesStatusBarAppearance = true
        controller.modalPresentationStyle = .overFullScreen
        return controller
    }
    
    init(questionLabelText: String){
        
        self.contentView = ContinuousCornersView(cornerRadius: 32)
        self.dimmingView = UIView()
        self.closeButton = IconButton()
        self.titleLabel = UILabel()
        self.questionText = UILabel()

        super.init(nibName: nil, bundle: nil)
        
        self.scoreSelectorView = QualityScoreSelectorView(onScoreSet: { [weak self] score in
            self?.delegate?.callQualityController(self!, didSelect: score)
        })
        
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimmingView.alpha = 0
    
        closeButton.setIcon(.X, with: .tiny, for: [], renderingMode: .alwaysTemplate)
        closeButton.accessibilityIdentifier = "score_close"
        closeButton.accessibilityLabel = NSLocalizedString("general.close", comment: "")
        closeButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        closeButton.clipsToBounds = true
        closeButton.adjustsImageWhenHighlighted = false
        
        let cancelVisualSelectionColor = UIColor(for: .strongBlue).withAlphaComponent(0.5)
        closeButton.setBackgroundImageColor(UIColor.cas_color(withHex: "#DAD9DF") , for: .normal)
        closeButton.setBackgroundImageColor(cancelVisualSelectionColor, for: .selected)
        closeButton.setBackgroundImageColor(cancelVisualSelectionColor, for: .highlighted)
        closeButton.setIconColor(.black, for: .normal)
        closeButton.setIconColor(.white, for: .selected)
        closeButton.setIconColor(.white, for: .highlighted)

        closeButton.addTarget(self, action: #selector(onCloseButtonTapped), for: .touchUpInside)
      
        titleLabel.textColor = UIColor.cas_color(withHex: "#323639")
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: UIFontWeightMedium)
        titleLabel.text = NSLocalizedString("calling.quality_survey.title", comment: "")
        titleLabel.adjustsFontSizeToFitWidth = true
        
        questionText.text = questionLabelText
        questionText.font = FontSpec(.normal, .regular).font
        questionText.textColor = UIColor.cas_color(withHex: "#323639").withAlphaComponent(0.56)
        questionText.textAlignment = .center
        questionText.numberOfLines = 0
        
        callQualityStackView = UICustomSpacingStackView(customSpacedArrangedSubviews: [titleLabel, questionText, scoreSelectorView])
        callQualityStackView.alignment = .center
        callQualityStackView.axis = .vertical
        callQualityStackView.spacing = 10
        callQualityStackView.wr_addCustomSpacing(24, after: titleLabel)
        callQualityStackView.wr_addCustomSpacing(32, after: questionText)
        
        dismissTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapToDismiss))
        dismissTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissTapGestureRecognizer)
        
        // Constraint
        
        iphone_leadingConstraint = contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8)
        iphone_trailingConstraint = contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)

        let bottomAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor>
        
        if #available(iOS 11, *) {
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        } else {
            bottomAnchor = view.bottomAnchor
        }

        iphone_bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ipad_centerYConstraint = contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ipad_centerXConstraint = contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func viewDidLoad() {

        contentView.backgroundColor = .white
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(dimmingView)
        view.addSubview(contentView)
        contentView.addSubview(closeButton)
        contentView.addSubview(callQualityStackView)
        
        constrain(view, dimmingView) { selfView, dimmingView in
            dimmingView.edges == selfView.edges
        }
        
        closeButton.layer.cornerRadius = 14
                
        constrain(closeButton) { closeButton in
            closeButton.right == (closeButton.superview!.right - 16)
            closeButton.width == 28
            closeButton.height == 28
        }
        
        constrain(callQualityStackView) { callQualityView in
            callQualityView.centerX == callQualityView.superview!.centerX
            callQualityView.width == (callQualityView.superview!.width - 32)
            callQualityView.bottom == (callQualityView.superview!.bottom - 24)
        }
        
        closeButton.bottomAnchor.constraint(equalTo: callQualityStackView.topAnchor, constant: -10).isActive = true
        contentView.topAnchor.constraint(equalTo: closeButton.topAnchor, constant: -24).isActive = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Dismiss Events
    
    func onCloseButtonTapped() {
        delegate?.callQualityControllerDidFinishWithoutScore(self)
    }
    
    func onTapToDismiss() {
        delegate?.callQualityControllerDidFinishWithoutScore(self)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view?.isDescendant(of: contentView) == false
    }
    
    override func accessibilityPerformMagicTap() -> Bool {
        onTapToDismiss()
        return true
    }
    
    // MARK: Adaptive Layout
    
    override func viewWillAppear(_ animated: Bool) {
        updateLayout(for: traitCollection)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in self.updateLayout(for: newCollection) })
    }
     
    private func updateLayout(for traitCollection: UITraitCollection) {
        
        switch traitCollection.horizontalSizeClass {
        case .regular:
            ipad_centerYConstraint.isActive = true
            ipad_centerXConstraint.isActive = true
            iphone_leadingConstraint.isActive = false
            iphone_trailingConstraint.isActive = false
            iphone_bottomConstraint.isActive = false

        default:
            ipad_centerYConstraint.isActive = false
            ipad_centerXConstraint.isActive = false
            iphone_leadingConstraint.isActive = true
            iphone_trailingConstraint.isActive = true
            iphone_bottomConstraint.isActive = true
        }

    }
    
}

class CallQualityView : UIStackView {
    let scoreLabel = UILabel()
    let scoreButton = Button()
    let callback: (Int)->()
    let labelText: String
    let buttonScore: Int
    
    init(labelText: String, buttonScore: Int, callback: @escaping (Int)->()){
        self.callback = callback
        self.buttonScore = buttonScore
        self.labelText = labelText
        
        super.init(frame: .zero)

        axis = .vertical
        spacing = 16
        scoreLabel.text = [1, 3, 5].contains(buttonScore) ? labelText : ""
        scoreLabel.font = FontSpec(.medium, .regular).font
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = UIColor.cas_color(withHex: "#272A2C")
        
        scoreButton.tag = buttonScore
        scoreButton.circular = true
        scoreButton.setTitle(String(buttonScore), for: .normal)
        scoreButton.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: UIFontWeightRegular)
        scoreButton.setTitleColor(UIColor.cas_color(withHex: "#272A2C"), for: .normal)
        scoreButton.setTitleColor(.white, for: .highlighted)
        scoreButton.setTitleColor(.white, for: .selected)
        scoreButton.addTarget(self, action: #selector(onClick), for: .primaryActionTriggered)
        scoreButton.setBackgroundImageColor(UIColor.cas_color(withHex: "#F8F8F8"), for: UIControlState.normal)
        scoreButton.setBackgroundImageColor(UIColor(for: .strongBlue) , for: UIControlState.highlighted)
        scoreButton.setBackgroundImageColor(UIColor(for: .strongBlue) , for: UIControlState.selected)
        scoreButton.accessibilityIdentifier = "score_\(buttonScore)"
        
        scoreButton.accessibilityLabel = labelText
        constrain(scoreButton){scoreButton in
            scoreButton.width == 56
            scoreButton.height == 56
        }
        
        addArrangedSubview(scoreLabel)
        addArrangedSubview(scoreButton)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func onClick(_ sender: UIButton) {
        callback(buttonScore)
    }
}

class QualityScoreSelectorView : UIView {
    private let scoreStackView = UIStackView()
    
    weak var delegate: CallQualityViewControllerDelegate?
    
    public let onScoreSet: ((Int)->())
    
    init(onScoreSet: @escaping (Int)->()) {
        self.onScoreSet = onScoreSet
        super.init(frame: .zero)
        
        scoreStackView.axis = .horizontal
        scoreStackView.distribution = .fillEqually
        scoreStackView.spacing = 8
        
        (1 ... 5)
            .map { (localizedNameForScore($0), $0) }
            .map { CallQualityView(labelText: $0.0, buttonScore: $0.1, callback: onScoreSet) }
            .forEach(scoreStackView.addArrangedSubview)
        
        addSubview(scoreStackView)
        constrain(self, scoreStackView) { selfView, scoreStackView in
            scoreStackView.edges == selfView.edges
        }
    }
    
    func localizedNameForScore(_ score: Int) -> String {
        return NSLocalizedString("calling.quality_survey.answer.\(score)", comment: "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

