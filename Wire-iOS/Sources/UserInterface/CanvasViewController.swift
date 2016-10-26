//
//  CanvasViewController.swift
//  Wire-iOS
//
//  Created by Jacob on 18/10/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Canvas
import Cartography

@objc protocol CanvasViewControllerDelegate : NSObjectProtocol {
    func canvasViewController(_ canvasViewController : CanvasViewController,  didExportImage image: UIImage)
}

@objc public enum ConversationMediaSketchSource : UInt {
    case none
    case sketchButton
    case cameraGallery
    case imageFullView
}

class CanvasViewController: UIViewController, UINavigationControllerDelegate {
    
    var delegate : CanvasViewControllerDelegate?
    var canvas = Canvas()
    var toolbar : SketchToolbar!
    let drawButton = IconButton()
    let emojiButton = IconButton()
    let sendButton = IconButton()
    let photoButton = IconButton()
    let separatorLine = UIView()
    let hintLabel = UILabel()
    let hintImageView = UIImageView()
    var source : ConversationMediaSketchSource = .none
    var sketchImage : UIImage? = nil {
        didSet {
            if let image = sketchImage {
                canvas.referenceImage = image
            }
            
        }
    }
    
    let emojiKeyboardViewController =  EmojiKeyboardViewController()
    let colorPickerController = SketchColorPickerController()
    
    public var wrapInNavigationController : UINavigationController {
        return wrap(inNavigationControllerClass: RotationAwareNavigationController.self)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        canvas.backgroundColor = .white
        canvas.delegate = self
        
        emojiKeyboardViewController.delegate = self
    
        toolbar = SketchToolbar(buttons: [photoButton, drawButton, emojiButton, sendButton])
        separatorLine.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSeparator)
        hintImageView.image = UIImage(for: .brush, fontSize: 172, color: ColorScheme.default().color(withName: ColorSchemeColorPlaceholderBackground))
        hintLabel.text = "sketchpad.initial_hint".localized.uppercased(with: Locale.current)
        hintLabel.numberOfLines = 0
        
        [canvas, hintLabel, hintImageView, toolbar, separatorLine].forEach(view.addSubview)
        
        if sketchImage != nil {
            hideHint()
        }
        
        configureNavigationItems()
        configureColorPicker()
        configureButtons()
        updateButtonSelection()
        createConstraints()
    }
    
    func configureNavigationItems() {
        let undoImage = UIImage(for: .undo, iconSize: .tiny, color: .black)
        let closeImage = UIImage(for: .X, iconSize: .tiny, color: .black)
        
        let closeButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(CanvasViewController.close))
        let undoButtonItem = UIBarButtonItem(image: undoImage, style: .plain, target: canvas, action: #selector(Canvas.undo))
        undoButtonItem.isEnabled = false
        
        navigationItem.leftBarButtonItem = undoButtonItem
        navigationItem.rightBarButtonItem = closeButtonItem
    }
    
    func configureButtons() {
        let hitAreaPadding = CGSize(width: 5, height: 5)
        
        sendButton.setIcon(.send, with: .tiny, for: .normal)
        sendButton.addTarget(self, action: #selector(exportImage), for: .touchUpInside)
        sendButton.isEnabled = false
        sendButton.cas_styleClass = "send-button"
        sendButton.hitAreaPadding = hitAreaPadding
        
        drawButton.setIcon(.brush, with: .tiny, for: .normal)
        drawButton.addTarget(self, action: #selector(selectDrawTool), for: .touchUpInside)
        drawButton.hitAreaPadding = hitAreaPadding
        
        photoButton.setIcon(.photo, with: .tiny, for: .normal)
        photoButton.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
        photoButton.hitAreaPadding = hitAreaPadding
        
        emojiButton.setIcon(.emoji, with: .tiny, for: .normal)
        emojiButton.addTarget(self, action: #selector(openEmojiKeyboard), for: .touchUpInside)
        emojiButton.hitAreaPadding = hitAreaPadding
    }
    
    func configureColorPicker() {
        
        colorPickerController.sketchColors = [.black,
                                              .white,
                                              UIColor(for: .strongBlue),
                                              UIColor(for: .strongLimeGreen),
                                              UIColor(for: .brightYellow),
                                              UIColor(for: .vividRed),
                                              UIColor(for: .brightOrange),
                                              UIColor(for: .softPink),
                                              UIColor(for: .violet),
                                              UIColor.cas_color(withHex: "#96bed6"),
                                              UIColor.cas_color(withHex: "#a3eba3"),
                                              UIColor.cas_color(withHex: "#fee7a3"),
                                              UIColor.cas_color(withHex: "#fda5a5"),
                                              UIColor.cas_color(withHex: "#ffd4a3"),
                                              UIColor.cas_color(withHex: "#fec4e7"),
                                              UIColor.cas_color(withHex: "#dba3fe"),
                                              UIColor.cas_color(withHex: "#a3a3a3")]
        
        colorPickerController.delegate = self
        colorPickerController.willMove(toParentViewController: self)
        view.addSubview(colorPickerController.view)
        addChildViewController(colorPickerController)
        colorPickerController.selectedColorIndex = UInt(colorPickerController.sketchColors.index(of: UIColor.accent()) ?? 0)
    }
    
    func createConstraints() {
        constrain(view, canvas, colorPickerController.view, toolbar, separatorLine) { container, canvas, colorPicker, toolbar, separatorLine in
            colorPicker.top == container.top
            colorPicker.left == container.left
            colorPicker.right == container.right
            colorPicker.height == 48
            
            separatorLine.top == colorPicker.bottom
            separatorLine.left == container.left
            separatorLine.right == container.right
            separatorLine.height == 0.5
            
            canvas.top == container.top
            canvas.left == container.left
            canvas.right == container.right
            
            toolbar.top == canvas.bottom
            toolbar.bottom == container.bottom
            toolbar.left == container.left
            toolbar.right == container.right
        }
        
        constrain(view, colorPickerController.view, hintImageView, hintLabel) { container, colorPicker, hintImageView, hintLabel in
            hintImageView.center == container.center
            hintLabel.top == colorPicker.bottom + 16
            hintLabel.leftMargin == container.leftMargin
            hintLabel.rightMargin == container.rightMargin
        }
    }
    
    func updateButtonSelection() {
        [drawButton, emojiButton].forEach({ $0.isSelected = false })
        
        switch canvas.mode {
        case .draw:
            drawButton.isSelected = true
        case .edit:
            emojiButton.isSelected = true
        }
    }
    
    func hideHint() {
        hintLabel.isHidden = true
        hintImageView.isHidden = true
    }
    
    // MARK - actions
    
    func selectDrawTool() {
        canvas.mode = .draw
        updateButtonSelection()
    }
    
    func openEmojiKeyboard() {
        showEmojiKeyboard()
    }
    
    func exportImage() {
        if let image = canvas.trimmedImage {
            delegate?.canvasViewController(self, didExportImage: image)
        }
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension CanvasViewController : CanvasDelegate {
    
    func canvasDidChange(_ canvas: Canvas) {
        sendButton.isEnabled = canvas.hasChanges
        navigationItem.leftBarButtonItem?.isEnabled = canvas.hasChanges
        hideHint()
    }
    
}

extension CanvasViewController : EmojiKeyboardViewControllerDelegate {
    
    func showEmojiKeyboard() {
        emojiKeyboardViewController.willMove(toParentViewController: self)
        view.addSubview(emojiKeyboardViewController.view)
        
        constrain(view, emojiKeyboardViewController.view) { container, emojiKeyboardView in
            emojiKeyboardView.height == KeyboardHeight.current
            emojiKeyboardView.left == container.left
            emojiKeyboardView.right == container.right
            emojiKeyboardView.bottom == container.bottom
        }
        
        addChildViewController(emojiKeyboardViewController)
    }
    
    func hideEmojiKeyboard() {
        guard childViewControllers.contains(emojiKeyboardViewController) else { return }
        
        emojiKeyboardViewController.willMove(toParentViewController: nil)
        emojiKeyboardViewController.view.removeFromSuperview()
        emojiKeyboardViewController.removeFromParentViewController()
    }
    
    func emojiKeyboardViewControllerDeleteTapped(_ viewController: EmojiKeyboardViewController) {
        
    }
    
    func emojiKeyboardViewController(_ viewController: EmojiKeyboardViewController, didSelectEmoji emoji: String) {
        
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 72)]
        let attributedEmoji = NSAttributedString(string: emoji, attributes: attributes)
        let size = attributedEmoji.size()
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        attributedEmoji.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image?.imageWithAlphaTrimmed {
            canvas.mode = .edit
            canvas.insert(image: image, at: canvas.center)
            updateButtonSelection()
        }
                
        hideEmojiKeyboard()
    }
}

extension CanvasViewController : UIImagePickerControllerDelegate {
    
    func pickImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        UIImagePickerController.loadImage(fromMediaInfo: info, result: { (image, _, _) in
            if let image = image, let cgImage = image.cgImage {
                self.canvas.referenceImage = UIImage(cgImage: cgImage, scale: 2, orientation: image.imageOrientation)
            }
            picker.dismiss(animated: true, completion: nil)
        }) { (error) in
            print("error: ", error)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

extension CanvasViewController : SketchColorPickerControllerDelegate {
    
    func sketchColorPickerController(_ controller: SketchColorPickerController, changedSelectedColor color: UIColor) {
        canvas.brush = Brush(size: Float(controller.brushWidth(for: color)), color: color)
    }

}
