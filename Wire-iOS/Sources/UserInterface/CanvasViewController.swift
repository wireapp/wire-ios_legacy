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

class CanvasViewController: UIViewController, UINavigationControllerDelegate {
    
    var delegate : CanvasViewControllerDelegate?
    var canvas : Canvas!
    var toolbar : SketchToolbar!
    let drawButton = IconButton()
    let emojiButton = IconButton()
    let sendButton = IconButton()
    let photoButton = IconButton()
    let separatorLine = UIView()
    
    let emojiKeyboardViewController =  EmojiKeyboardViewController()
    let colorPickerController = SketchColorPickerController()
    
    public var wrapInNavigationController : UINavigationController {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        navigationController.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(magicIdentifier: "style.text.title.font_spec"), NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground)]
        navigationController.navigationBar.barTintColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
        return navigationController
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        canvas = Canvas()
        canvas.backgroundColor = .white
        
        emojiKeyboardViewController.delegate = self
    
        toolbar = SketchToolbar(buttons: [photoButton, drawButton, emojiButton, sendButton])
        separatorLine.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSeparator)
        
        [canvas, toolbar, separatorLine].forEach(view.addSubview)
        
        configureNavigationItems()
        configureColorPicker()
        configureButtons()
        createConstraints()
    }
    
    func configureNavigationItems() {
        let undoImage = UIImage(for: .undo, iconSize: .tiny, color: .black)
        let closeImage = UIImage(for: .X, iconSize: .tiny, color: .black)
        
        let closeButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(CanvasViewController.close))
        let undoButtonItem = UIBarButtonItem(image: undoImage, style: .plain, target: canvas, action: #selector(Canvas.undo))
        
        navigationItem.leftBarButtonItem = undoButtonItem
        navigationItem.rightBarButtonItem = closeButtonItem
    }
    
    func configureButtons() {
        sendButton.setIcon(.send, with: .tiny, for: .normal)
        sendButton.addTarget(self, action: #selector(exportImage), for: .touchUpInside)
        
        drawButton.setIcon(.brush, with: .tiny, for: .normal)
        drawButton.addTarget(self, action: #selector(selectDrawTool), for: .touchUpInside)
        
        photoButton.setIcon(.photo, with: .tiny, for: .normal)
        photoButton.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
        
        emojiButton.setIcon(.emoji, with: .tiny, for: .normal)
        emojiButton.addTarget(self, action: #selector(openEmojiKeyboard), for: .touchUpInside)
    }
    
    /*
     NSArray *sketchColors = @[[UIColor blackColor],
     [UIColor whiteColor],
     [UIColor colorForZMAccentColor:ZMAccentColorStrongBlue],
     [UIColor colorForZMAccentColor:ZMAccentColorStrongLimeGreen],
     [UIColor colorForZMAccentColor:ZMAccentColorBrightYellow],
     [UIColor colorForZMAccentColor:ZMAccentColorVividRed],
     [UIColor colorForZMAccentColor:ZMAccentColorBrightOrange],
     [UIColor colorForZMAccentColor:ZMAccentColorSoftPink],
     [UIColor colorForZMAccentColor:ZMAccentColorViolet],
     [UIColor cas_colorWithHex:@"#96bed6"],
     [UIColor cas_colorWithHex:@"#a3eba3"],
     [UIColor cas_colorWithHex:@"#fee7a3"],
     [UIColor cas_colorWithHex:@"#fda5a5"],
     [UIColor cas_colorWithHex:@"#ffd4a3"],
     [UIColor cas_colorWithHex:@"#fec4e7"],
     [UIColor cas_colorWithHex:@"#dba3fe"],
     [UIColor cas_colorWithHex:@"#a3a3a3"]];
 */
    
    func configureColorPicker() {
        
        colorPickerController.sketchColors = [.black,
                                              .white,
                                              UIColor(for: .strongBlue),
                                              UIColor(for: .strongLimeGreen),
                                              UIColor(for: .brightYellow),
                                              UIColor(for: .vividRed),
                                              UIColor(for: .brightOrange),
                                              UIColor(for: .softPink),
                                              UIColor(for: .violet)]
        
        colorPickerController.delegate = self
        colorPickerController.selectedColorIndex = UInt(colorPickerController.sketchColors.index(of: UIColor.accent()) ?? 0)
        colorPickerController.willMove(toParentViewController: self)
        view.addSubview(colorPickerController.view)
        addChildViewController(colorPickerController)
        
        
        
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
    }
    
    // MARK - actions
    
    func selectDrawTool() {
        canvas.mode = .draw
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
        let size = (emoji as NSString).size(attributes: attributes)
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        (emoji as NSString).draw(in: rect, withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            canvas.mode = .edit
            canvas.insert(image: image, at: canvas.center)
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
