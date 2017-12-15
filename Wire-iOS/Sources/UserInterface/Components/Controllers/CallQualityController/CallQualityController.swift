//
//  CallQualityController.swift
//  Wire-iOS
//
//  Created by Juliane Reschke on 26.10.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//
//  This UI component is build for Juliane Reschkes Master Thesis.

import Foundation
import Cartography

struct RatingState {
    var rating1: Int? = nil
    var rating2: Int? = nil
}

class BaseCallQualityViewController :  UIViewController {

    let root = CallQualityViewController(questionLabelText: "How do you rate the call set up?")
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
            let next = CallQualityViewController(questionLabelText: "How do you rate the overall quality of the call?")
            next.delegate = self
            baseNavigationController.pushViewController(next, animated: true)
        }
        else {
            ratingState.rating2 = score
            print("Rating: \(ratingState)")
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
//    let descriptionText : UILabel
    let mosTextView : MOSQualityScoreTextView
    let scoreSelectorView : QualityScoreSelectorView
//    let bigButton : Button
    var questionLabelText = String()
    var buttonText = String()
    weak var delegate: CallQualityViewControllerDelegate?
    
    init(questionLabelText: String){
        callQualityView.axis = .vertical
        
        self.titleLabel = UILabel()
        self.questionText = UILabel()
//        self.descriptionText = UILabel()
        self.mosTextView = MOSQualityScoreTextView()
        self.scoreSelectorView = QualityScoreSelectorView()
//        self.bigButton = Button()
        
        super.init(nibName: nil, bundle: nil)
        
        titleLabel.textColor = UIColor.black
        titleLabel.font = FontSpec(.large, .semibold).font
        titleLabel.text = "Call Quality Survey".uppercased()
        
        questionText.text = questionLabelText.uppercased()
        questionText.font = FontSpec(.normal, .medium).font
        questionText.textColor = UIColor.black
        questionText.numberOfLines = 0
        
//        descriptionText.text = "The scale ranges: bad(1) - poor(2) - fair(3) - good(4) - excellent(5)"
//        descriptionText.font = FontSpec(.medium, .regular).font
//        descriptionText.textColor = UIColor.black
//        descriptionText.numberOfLines = 0
     
        
//        bigButton.setTitle(buttonText.uppercased(), for: UIControlState.normal)
//        bigButton.setBackgroundImageColor(UIColor.green, for: UIControlState.normal)
//        bigButton.isEnabled = false
//        bigButton.addTarget(self, action: #selector(onClick), for: .primaryActionTriggered)
//
        scoreSelectorView.onScoreSet = { [weak self] _ in
//            self?.bigButton.isEnabled = true
             self?.delegate?.controller(self!, didSelect: (self?.scoreSelectorView.score)!)
        }
        callQualityView.addArrangedSubview(titleLabel)
        callQualityView.addArrangedSubview(questionText)
//        callQualityView.addArrangedSubview(descriptionText)
        callQualityView.addArrangedSubview(mosTextView)
        callQualityView.addArrangedSubview(scoreSelectorView)
//        callQualityView.addArrangedSubview(bigButton)
        callQualityView.spacing = 40
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        view.addSubview(callQualityView)
        
        constrain(callQualityView) { callQualityView in
            callQualityView.center == callQualityView.superview!.center
            callQualityView.width <= callQualityView.superview!.width - 100
        }
    }
    
//    func onClick(_ sender: Button) {
//        delegate?.controller(self, didSelect: scoreSelectorView.score)
//    }

}

class QualityScoreSelectorView : UIView {
    private let scoreStackView = UIStackView()
    private var scoreButtons: [UIButton] = []
    let imageNormal = UIImage(named: "scoreButtonNormalState.png")
    let imageSelected = UIImage(named: "scoreButtonSelectedState.png")
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
        let scoreValues = [1,2,3,4,5]
        scoreButtons = scoreValues.map { (scoreValue) in
            let button = UIButton()
            button.tag = scoreValue
            button.setTitle(String(scoreValue), for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(.white, for: .selected)

            button.addTarget(self, action: #selector(onClick), for: .primaryActionTriggered)
            button.setBackgroundImage(imageNormal, for: UIControlState.normal)
            button.setBackgroundImage(imageSelected, for: UIControlState.selected)
            self.scoreStackView.addArrangedSubview(button)
            constrain(button){button in
                button.width == 40
                button.height == 40
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
//        delegate?.controller(CallQualityViewController, didSelect: scoreStackView.score)
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
        
        mos1Label.text = "Bad"
        mos1Label.font = FontSpec(.medium, .regular).font
        mos1Label.textColor = UIColor.black
        
        mos2Label.text = "Poor"
        mos2Label.font = FontSpec(.medium, .regular).font
        mos2Label.textColor = UIColor.black
        
        mos3Label.text = "Fair"
        mos3Label.font = FontSpec(.medium, .regular).font
        mos3Label.textColor = UIColor.black
        
        mos4Label.text = "Good"
        mos4Label.font = FontSpec(.medium, .regular).font
        mos4Label.textColor = UIColor.black
        
        mos5Label.text = "Excellent"
        mos5Label.font = FontSpec(.medium, .regular).font
        mos5Label.textColor = UIColor.black
        
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
