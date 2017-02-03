//
//  SCBodyView.swift
//  XXXXX
//
//  Created by McKinley, Andrew on 3/22/16.
//  Copyright © 2016 XXXXX. All rights reserved.
//

import UIKit
import XXXXCommonFramework

@objc protocol SCBodyViewDelegate : class{
    func selectBodyPartWithID(_ _partID:Int, withLabel _labelText:String)
    @objc optional func didShowBody(_ _isFront:Bool)
    @objc optional func bodyDidFlip()
    func showHelp()
    
}

@objc class SCBodyView: UIView {
    
    let scrollView:UIScrollView = UIScrollView()
    
    let flipButton:UIButton = UIButton(type: .custom)
	let flipButtonText: UIButton = UIButton(type: .custom)
    let helpButton:UIButton = UIButton(type: .custom)
	let helpButtonText:UIButton = UIButton(type: .custom)
    
    var gender:SCGENDER!
    weak var delegate:SCBodyViewDelegate!
    var scImageView:SCImageView!
    
    var numberOfBodyParts:Int32?
    var paths:UnsafeMutablePointer<UnsafeMutablePointer<Int32>>?
    var pathIdentifiers:UnsafeMutablePointer<Int32>?
    var pathLenth:UnsafeMutablePointer<Int32>?
	var zoomLabel: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>?
	
    var bodyImageWidth:CGFloat!
    var bodyImageHeight:CGFloat!


    var isZoomed:Bool = false
    var isBack:Bool = false
    
    var currentScale:CGFloat = 1
    
    //MARK: Lifecycle
    required convenience init(withGender _gender:SCGENDER, delegate _delegate:SCBodyViewDelegate, andFrame _frame:CGRect){
        self.init()
        self.gender = _gender
        self.delegate = _delegate
        
        self.setUpScrollView()
        self.setUpFlipButton()
        self.setUpHelpButton()
        self.setUpBodyImage(withFrame: _frame)
        self.bodyImageHeight = _frame.size.height
        self.bodyImageWidth = _frame.size.width
        self.isUserInteractionEnabled = true
        self.clipsToBounds = true
        SCStylingHelper.equallyConstrain(subivew: self.scrollView, toSuperview: self, withInsets: UIEdgeInsets.zero, andIdentifier: "scrollViewConst")
        self.updateConstraints()
        self.flipButton.accessibilityIdentifier = SCSymptomConfig.accessibilityIdentifiers.rootVC.flipButton
        self.helpButton.accessibilityIdentifier = SCSymptomConfig.accessibilityIdentifiers.rootVC.helpButton
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        self.centerContent()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateConstraints()
        self.scrollView.contentSize = CGSize(width: self.bodyImageWidth, height: self.bodyImageHeight)
        self.updateImageData()
    }
    
    //MARK: Layout
    fileprivate func setUpScrollView(){
        self.scrollView.backgroundColor = UIColor.clear
        self.scrollView.scrollsToTop = false
        self.scrollView.delaysContentTouches = true
        self.scrollView.maximumZoomScale = 3
        self.scrollView.minimumZoomScale = 1
        self.scrollView.zoomScale = 1

        self.scrollView.isScrollEnabled = true
        self.scrollView.delegate = self
        self.scrollView.clipsToBounds = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.isUserInteractionEnabled = true
        
        self.addSubview(self.scrollView)
    }
    
    fileprivate func setUpBodyImage(withFrame _frame:CGRect){
        self.scImageView = SCImageView(frame: _frame)
        self.updateImage()
        self.scImageView.delegate = self
        self.scImageView.isUserInteractionEnabled = true
        self.scrollView.addSubview(self.scImageView)
    }
    
    //MARK: Response Methods
    func updateGender(_ _gender:SCGENDER){
        self.gender = _gender
        self.updateImageData()
    }
    
    func userClickedFlip(){
        self.isBack = !self.isBack
        self.updateImageData()
		self.delegate.bodyDidFlip?()
    }
    
    func userClickedHelp(){
        self.delegate.showHelp()
    }
    
    // MARK: Private Methods
    fileprivate func updateImageData(){
        self.updateImage()
        if self.gender == SCMALE{
            if self.isBack{
                self.setBackMale()
            } else {
                self.setFrontMale()
            }
        } else {
            if self.isBack{
                self.setBackFemale()
            } else {
                self.setFrontFemale()
            }
        }
        self.configureImageHitAreas()
    }
    
    fileprivate func updateImage(){
        if self.isBack{
            self.scImageView.image = UIImage(named: self.gender == SCMALE ? SCSymptomConfig.imageNames.backMale : SCSymptomConfig.imageNames.backFemale)
        } else {
            self.scImageView.image = UIImage(named: self.gender == SCMALE ? SCSymptomConfig.imageNames.frontMale : SCSymptomConfig.imageNames.frontFemale)
        }
    }
    
    fileprivate func setFrontMale(){
        self.numberOfBodyParts = self.isZoomed ? male_front_zoom_in_total_body_parts : male_front_zoom_out_total_body_parts
        self.paths = self.isZoomed ? male_front_zoom_in_path_external : male_front_zoom_out_path_external
        self.pathLenth = self.isZoomed ? male_front_zoom_in_path_length_external : male_front_zoom_out_path_length_external
        self.pathIdentifiers = self.isZoomed ? male_front_zoom_in_id_external : male_front_zoom_out_id_external
        self.zoomLabel = self.isZoomed ? male_front_zoom_in_label_external : male_front_zoom_out_label_external
    }
  
    fileprivate func setBackMale(){
        self.numberOfBodyParts = self.isZoomed ? male_back_zoom_in_total_body_parts : male_back_zoom_out_total_body_parts
        self.paths = self.isZoomed ? male_back_zoom_in_path_external : male_back_zoom_out_path_external
        self.pathLenth = self.isZoomed ? male_back_zoom_in_path_length_external : male_back_zoom_out_path_length_external
        self.pathIdentifiers = self.isZoomed ? male_back_zoom_in_id_external : male_back_zoom_out_id_external
        self.zoomLabel = self.isZoomed ? male_back_zoom_in_label_external : male_back_zoom_out_label_external
    }
    
    fileprivate func setFrontFemale(){
        self.numberOfBodyParts = self.isZoomed ? female_front_zoom_in_total_body_parts : female_front_zoom_out_total_body_parts
        self.paths = self.isZoomed ? female_front_zoom_in_path_external : female_front_zoom_out_path_external
        self.pathLenth = self.isZoomed ? female_front_zoom_in_path_length_external : female_front_zoom_out_path_length_external
        self.pathIdentifiers = self.isZoomed ? female_front_zoom_in_id_external : female_front_zoom_out_id_external
        self.zoomLabel = self.isZoomed ? female_front_zoom_in_label_external : female_front_zoom_out_label_external
    }
    
    fileprivate func setBackFemale(){
        self.numberOfBodyParts = self.isZoomed ? female_back_zoom_in_total_body_parts : female_back_zoom_out_total_body_parts
        self.paths = self.isZoomed ? female_back_zoom_in_path_external : female_back_zoom_out_path_external
        self.pathLenth = self.isZoomed ? female_back_zoom_in_path_length_external : female_back_zoom_out_path_length_external
        self.pathIdentifiers = self.isZoomed ? female_back_zoom_in_id_external : female_back_zoom_out_id_external
        self.zoomLabel = self.isZoomed ? female_back_zoom_in_label_external : female_back_zoom_out_label_external
    }
    
    fileprivate func configureImageHitAreas(){
        if  let bodyParts = self.numberOfBodyParts,
            let lenths = self.pathLenth,
            let paths = self.paths,
            let ids = self.pathIdentifiers,
            let label = self.zoomLabel{
              self.scImageView.configureHitDetection(withNumberBodyParts: bodyParts, pathLengths: lenths, paths: paths, partIdentifers: ids, partNames: label)
        }
    }
    
    fileprivate func setUpFlipButton(){
        self.addSubview(self.flipButton)
        self.flipButton.translatesAutoresizingMaskIntoConstraints = false
        self.flipButton.backgroundColor = UIColor.clear
        self.flipButton.addTarget(self, action: #selector(self.userClickedFlip), for: .touchUpInside)

		self.flipButton.setImage(WebMD_StyleKit.imageOfFlip(), for: UIControlState())
		self.flipButton.addConstraints(.H, XXXXConstraintBuilder(flipButton, .equal1(to: 22)))
			self.flipButton.addConstraints(.V, XXXXConstraintBuilder(flipButton, .equal1(to: 22)))
		
		//       self.flipButton.accessibilityIdentifier = SCSymptomConfig.accessibilityIdentifiers.flip
        
        let leadingConst = NSLayoutConstraint(item: self.flipButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: SCSymptomConfig.padding.bodyViewPadding)
        let bottomConst = NSLayoutConstraint(item: self.flipButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -SCSymptomConfig.padding.bodyViewPadding)
        self.addConstraints([leadingConst,bottomConst])
		
		self.addSubview(self.flipButtonText)
		self.flipButtonText.translatesAutoresizingMaskIntoConstraints = false
		self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[flipbutton]-3-[fliptext]", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["flipbutton": self.flipButton, "fliptext": self.flipButtonText]))
		self.flipButtonText.setAttributedTitle(NSAttributedString(string: XXXXFlagshipStrings._Flip.localizedString, attributes: [
			NSFontAttributeName : UIFont.defaultFont(ofSize: 16, weight: XXXXWeightedFont.regular),
			NSForegroundColorAttributeName : UIColor.webmdBlueColor()
			]), for: UIControlState())
		self.flipButtonText.addTarget(self, action: #selector(self.userClickedFlip), for: .touchUpInside)
    }
    
    fileprivate func setUpHelpButton(){
        self.addSubview(self.helpButton)
        self.helpButton.translatesAutoresizingMaskIntoConstraints = false
        self.helpButton.backgroundColor = UIColor.clear
        self.helpButton.addTarget(self, action: #selector(SCBodyView.userClickedHelp), for: .touchUpInside)

		self.helpButton.setImage(WebMD_StyleKit.imageOfHelp(), for: UIControlState())
		self.helpButton.addConstraints(.H, XXXXConstraintBuilder(helpButton, .equal1(to: 22)))
		self.helpButton.addConstraints(.V, XXXXConstraintBuilder(helpButton, .equal1(to: 22)))
   //     self.helpButton.accessibilityIdentifier = SCSymptomConfig.accessibilityIdentifiers.help
        
        let trailingConst = NSLayoutConstraint(item: self.helpButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -SCSymptomConfig.padding.bodyViewPadding)
        let bottomConst = NSLayoutConstraint(item: self.helpButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -SCSymptomConfig.padding.bodyViewPadding)
        self.addConstraints([trailingConst,bottomConst])
		
		self.addSubview(self.helpButtonText)
		self.helpButtonText.translatesAutoresizingMaskIntoConstraints = false
		self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[helptext]-3-[helpbutton]", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["helpbutton": self.helpButton, "helptext": self.helpButtonText]))
		self.helpButtonText.setAttributedTitle(NSAttributedString(string: XXXXFlagshipStrings._Help.localizedString, attributes: [
			NSFontAttributeName : UIFont.defaultFont(ofSize: 16, weight: XXXXWeightedFont.regular),
			NSForegroundColorAttributeName : UIColor.webmdBlueColor()
			]), for: UIControlState())
		self.helpButtonText.addTarget(self, action: #selector(self.userClickedHelp), for: .touchUpInside)
    }
    
    fileprivate func centerContent(){
        if UIApplication.shared.statusBarOrientation == .portrait {
            self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        } else {
            let leftOffset = (self.scrollView.bounds.size.width - self.scrollView.contentSize.width)/2
            self.scrollView.contentInset = UIEdgeInsetsMake(0, leftOffset, 0, 0)
        }
    }
}

extension SCBodyView : UIScrollViewDelegate{
    
    internal func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if scale > 1 {
            if !self.isZoomed{
                self.isZoomed = true
                self.updateImageData()
            }
        } else {
            if self.isZoomed{
                self.isZoomed = false
                self.updateImageData()
            }
        }
        self.currentScale = scale
        self.scImageView.zoomSize = scale
        self.centerContent()
    }
    
    internal func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.scImageView
    }
}

extension SCBodyView : SCImageViewDelegate{
    func onBodyPartSelected(withID partID: Int32, withLabel partLabel: String) {
        self.delegate.selectBodyPartWithID(Int(partID), withLabel: partLabel)
    }

}
