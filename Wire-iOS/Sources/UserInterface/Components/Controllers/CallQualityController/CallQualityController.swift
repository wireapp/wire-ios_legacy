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

struct RatingState {
    var rating1: Int? = nil
    var rating2: Int? = nil
}

class BaseCallQualityViewController :  UIViewController {

    let root = CallQualityViewController(questionLabelText: "1/2 How do you rate the call set up time?")
    let baseNavigationController : UINavigationController

    var ratingState: RatingState = RatingState(rating1: nil, rating2: nil)
    
    init(){
        self.baseNavigationController = UINavigationController()
        super.init(nibName: nil, bundle: nil)
        root.delegate = self
        baseNavigationController.setNavigationBarHidden(true, animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.addSubview(baseNavigationController.view)
        baseNavigationController.pushViewController(root, animated: true)
    }

}

extension BaseCallQualityViewController: CallQualityViewControllerDelegate {
    func controller(_ controller: CallQualityViewController, didSelect score: Int) {
        if controller == root {
            ratingState.rating1 = score
            let next = CallQualityViewController(questionLabelText: "2/2 How do you rate the overall\nquality of the call?")
            next.delegate = self
            baseNavigationController.pushViewController(next, animated: true)
        }
        else {
            ratingState.rating2 = score
            self.dismiss(animated: true, completion: nil)
            
            CallQualityScoreProvider.shared.userScore = ratingState
        }
    }
}

protocol CallQualityViewControllerDelegate: class {
    func controller(_ controller: CallQualityViewController, didSelect score: Int)
}

class CallQualityViewController : UIViewController {

    var callQualityStackView : UICustomSpacingStackView!
    let titleLabel : UILabel
    let questionText : UILabel
    var scoreSelectorView : QualityScoreSelectorView!
    var questionLabelText = String()
    weak var delegate: CallQualityViewControllerDelegate?
    
    init(questionLabelText: String){
        
        self.titleLabel = UILabel()
        self.questionText = UILabel()

        super.init(nibName: nil, bundle: nil)
        
        self.scoreSelectorView = QualityScoreSelectorView(onScoreSet: { [weak self] score in
            self?.delegate?.controller(self!, didSelect: score)
        })
        
        titleLabel.textColor = UIColor.cas_color(withHex: "#323639")
        titleLabel.font = UIFont.systemFont(ofSize: 40, weight: UIFontWeightLight)
        titleLabel.text = "Call Quality Survey"
        
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
        callQualityStackView.wr_addCustomSpacing(48, after: questionText)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func viewDidLoad() {
        view.backgroundColor = UIColor.cas_color(withHex: "#F8F8F8")
        view.addSubview(callQualityStackView)
        
        constrain(callQualityStackView) { callQualityView in
            callQualityView.center == callQualityView.superview!.center
            callQualityView.width <= callQualityView.superview!.width
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
        scoreLabel.text = labelText
        scoreLabel.font = FontSpec(.medium, .regular).font
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = UIColor.cas_color(withHex: "#272A2C")
        
        scoreButton.tag = buttonScore
        scoreButton.circular = true
        scoreButton.setTitle(String(buttonScore), for: .normal)
        scoreButton.setTitleColor(UIColor.cas_color(withHex: "#272A2C"), for: .normal)
        scoreButton.setTitleColor(.white, for: .highlighted)
        scoreButton.setTitleColor(.white, for: .selected)
        scoreButton.addTarget(self, action: #selector(onClick), for: .primaryActionTriggered)
        scoreButton.setBackgroundImageColor(.white, for: UIControlState.normal)
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
        scoreStackView.distribution = .equalCentering
        scoreStackView.spacing = 8
        
        [("Bad", 1), ("Poor", 2), ("Fair", 3), ("Good", 4), ("Excellent", 5)]
            .map { CallQualityView( labelText: $0.0, buttonScore: $0.1, callback: onScoreSet) }
            .forEach(scoreStackView.addArrangedSubview)
        
        addSubview(scoreStackView)
        constrain(self, scoreStackView) { selfView, scoreStackView in
            scoreStackView.edges == selfView.edges
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

