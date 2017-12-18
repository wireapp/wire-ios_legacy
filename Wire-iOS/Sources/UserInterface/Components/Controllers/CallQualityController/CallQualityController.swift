//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

    let root = CallQualityViewController(questionLabelText: "1. How do you rate the call set up?")
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
            let next = CallQualityViewController(questionLabelText: "2. How do you rate the overall quality of the call?")
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
    
    let callQualityView = UIStackView()
    let titleLabel : UILabel
    let questionText : UILabel
    let mosTextView : MOSQualityScoreTextView
    let scoreSelectorView : QualityScoreSelectorView
    var questionLabelText = String()
    weak var delegate: CallQualityViewControllerDelegate?
    
    init(questionLabelText: String){
        callQualityView.axis = .vertical
        callQualityView.alignment = .center
        
        self.titleLabel = UILabel()
        self.questionText = UILabel()
        self.mosTextView = MOSQualityScoreTextView()
        self.scoreSelectorView = QualityScoreSelectorView()
        
        super.init(nibName: nil, bundle: nil)
        
        titleLabel.textColor = UIColor.cas_color(withHex: "#323639").withAlphaComponent(1.0)
        titleLabel.font = FontSpec(.large, .medium).font
        titleLabel.text = "Call Quality Survey"
        
        questionText.text = questionLabelText
        questionText.font = FontSpec(.normal, .regular).font
        questionText.textColor = UIColor.cas_color(withHex: "#323639").withAlphaComponent(0.56)
        questionText.numberOfLines = 0

        scoreSelectorView.onScoreSet = { [weak self] _ in
             self?.delegate?.controller(self!, didSelect: (self?.scoreSelectorView.score)!)
        }
        callQualityView.addArrangedSubview(titleLabel)
        if #available(iOS 11.0, *) {
            callQualityView.setCustomSpacing(24, after: titleLabel)
        } else {
            // Fallback on earlier versions
        }
        callQualityView.addArrangedSubview(questionText)
        if #available(iOS 11.0, *) {
            callQualityView.setCustomSpacing(48, after: questionText)
        } else {
            // Fallback on earlier versions
        }
        callQualityView.addArrangedSubview(mosTextView)
        callQualityView.addArrangedSubview(scoreSelectorView)
        callQualityView.spacing = 10
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.cas_color(withHex: "#F8F8F8")
        view.addSubview(callQualityView)
        
        constrain(callQualityView) { callQualityView in
            callQualityView.center == callQualityView.superview!.center
            callQualityView.width <= callQualityView.superview!.width - 32
        }
    }
}

class QualityScoreSelectorView : UIView {
    private let scoreStackView = UIStackView()
    private var scoreButtons: [Button] = []
    weak var delegate: CallQualityViewControllerDelegate?
    
    public var onScoreSet: ((Int)->())? = nil
    
    var score: Int = 0 {
        didSet {
            onScoreSet?(score)
        }
    }
    
    override init(frame: CGRect) {

        super.init(frame: frame)
        
        scoreStackView.axis = .horizontal
        scoreStackView.distribution = .equalCentering
        scoreStackView.spacing = 20
        let scoreValues = [1,2,3,4,5]
        scoreButtons = scoreValues.map { (scoreValue) in
            let button = Button()
            button.tag = scoreValue
            button.circular = true
            button.setTitle(String(scoreValue), for: .normal)
            button.setTitleColor(UIColor.cas_color(withHex: "#272A2C"), for: .normal)
            button.setTitleColor(.white, for: .selected)

            button.addTarget(self, action: #selector(onClick), for: .primaryActionTriggered)
            button.setBackgroundImageColor(.white, for: UIControlState.normal)
            button.setBackgroundImageColor(UIColor.blue , for: UIControlState.selected)
            self.scoreStackView.addArrangedSubview(button)
            constrain(button){button in
                button.width == 56
                button.height == 56
            }
    
            return button
        }
        addSubview(scoreStackView)
        constrain(self, scoreStackView) { selfView, scoreStackView in
            scoreStackView.edges == selfView.edges
        }
    }
    
    func onClick(_ sender: UIButton) {
        for sender in scoreButtons{
            sender.isSelected = false
        }
        self.score = sender.tag
        sender.isSelected = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class MOSQualityScoreTextView : UIView {
    
    private let mosTextStackView = UIStackView()
    let mos1Label = UILabel()
    let mos2Label = UILabel()
    let mos3Label = UILabel()
    let mos4Label = UILabel()
    let mos5Label = UILabel()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        mosTextStackView.axis = .horizontal
        mosTextStackView.distribution = .equalCentering
        mosTextStackView.spacing = 35
        
        mos1Label.text = "Bad"
        mos1Label.font = FontSpec(.medium, .regular).font
        mos1Label.textColor = UIColor.cas_color(withHex: "#272A2C")
        
        mos2Label.text = "Poor"
        mos2Label.font = FontSpec(.medium, .regular).font
        mos2Label.textColor = UIColor.cas_color(withHex: "#272A2C")
        
        mos3Label.text = "Fair"
        mos3Label.font = FontSpec(.medium, .regular).font
        mos3Label.textColor = UIColor.cas_color(withHex: "#272A2C")
        
        mos4Label.text = "Good"
        mos4Label.font = FontSpec(.medium, .regular).font
        mos4Label.textColor = UIColor.cas_color(withHex: "#272A2C")
        
        mos5Label.text = "Excellent"
        mos5Label.font = FontSpec(.medium, .regular).font
        mos5Label.textColor = UIColor.cas_color(withHex: "#272A2C")
        
        self.mosTextStackView.addArrangedSubview(mos1Label)
        self.mosTextStackView.addArrangedSubview(mos2Label)
        self.mosTextStackView.addArrangedSubview(mos3Label)
        self.mosTextStackView.addArrangedSubview(mos4Label)
        self.mosTextStackView.addArrangedSubview(mos5Label)

        addSubview(mosTextStackView)
        constrain(self, mosTextStackView) { selfView, mosTextStackView in
            mosTextStackView.edges == selfView.edges
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
