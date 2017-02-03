
//  Created by McKinley, Andrew on 9/14/16.
//  Copyright © 2016 XXXXX. All rights reserved.
//

import UIKit

@objc public enum XXXXBaseAdSize:Int{
    case kBanner
    case kLargeBanner
    case kMediumRectangle
    case kFullBanner
    case kLeaderBoard
    case kSmartBannerPortrait
    case kSmartBannerLandscape
}

// label above ad that says "ADVERTISEMENT"
@objc public enum AdDistinctionType:Int{
    case none
    case subtle // Black text, transparent bacground
    case overt  // White text, dark grey background
}

/*
XXXXBaseAdManager is a wrapper for your ads. It is accompanied by XXXXBaseAdParameters which must be used also. When used without subclassing it will return a blank view with a red background representing the ad with the specified dimensions. Subclassing is absolutely necessary. Subclass should override requestBanner and implement requesting of ads specific to the ad framework used. Successes and failures should call didRecieveBanner block/closure
 
 General Usage:
        1. Subclass XXXXBaseAdManager overriding requestBanner to use specific ad framework (ex: GoogleMobileAds)
        2. Subclass XXXXBaseAdParameters to manage customized parameters. Subclass should convert XXXXBaseAdSize enum into value appropriate to specific ad framework
        3. After instantiating class set completion block/closure
        4. Call request banner with XXXXBaseAdParameters
        5. Returned ads should be wrapped in XXXXAdContainer. Use wrapAdInContainer for convience
        6. didRecieveBanner should be called regardless of success
 
 Session Mangager:
    This class maintains an ad session with the following rules:
        1. Random session number betwen 1-20 is assigned upon loading the app
        2. Session number is maintained until the user backgrounds the app for more than 30 mintues
        3. Closing the app and restarting assigns new session number regardless of last logged in time
        4. To use external session manager, override class method getAdSessionNumber
 
 */

@objc open class XXXXBaseAdManager: NSObject {
    public var didRecieveBanner:((_ banner:XXXXAdContainer?,_ success:Bool, _ root:UIViewController?)->Void)?
    fileprivate static let sessionKey:String = "SessionKey"
    fileprivate static let sessionCountKey:String = "SessionCountKey"
    fileprivate static let sessionVersionKey:String = "SessionVersionKey"
    fileprivate static let lastLoggedInKey:String = "LastLoggedInKey"
    
    // Override in sublcass if needed
    fileprivate static let totalAdSessions:Int = 20
    fileprivate static let sessionTimeout:Int = 30 //minutes
    
    // Override me for live ads
    @objc open func requestBanner(withParameters params:XXXXBaseAdParameters){
        if self.didRecieveBanner == nil{
            print("ERROR!!! bannerCompletion closure ABSOLUTELY NECESSARY !!!")
            return
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                if let custom = params.customSizes?[0], params.useCustomSizesExclusively{
                    self.didRecieveBanner?(self.wrapAdInContainer(ad: self.getBlankAd(size: custom), withDistinctionType: .overt),false,params.rootVC)
                } else {
                    self.didRecieveBanner?(self.wrapAdInContainer(ad: self.getBlankAd(), withDistinctionType: .overt),false,params.rootVC)
                }
            })
        }
    }
    
    // Override me if seperate session manager is used
    @objc open class func getAdSessionNumber()->Int{
        return XXXXBaseAdManager.getAdSession()
    }
    
    // Gets incremented everytime we generate a new ad session number
    @objc open class func getAdSessionCountNumber()->Int{
        return XXXXBaseAdManager.getAdSessionCount()
    }

    // Resets ad session
    @objc open class func resetAdSessionNumber(){
        XXXXBaseAdManager.resetAdSession()
    }
    
    // Resets ad session count
    @objc open class func resetAdSessionCountNumber(){
        XXXXBaseAdManager.resetAdSessionCount()
    }
    
    // put me in applicationDidEnterBackground
    @objc public class func userLeftApp(){
        XXXXBaseAdManager.setLoggedOut()
    }
    
    //put me in didFinishLaunchingWithOptions (forStartup:true) and applicationDidBecomeActive (forStartup:false)
    @objc public class func configureAppSession(forStartup:Bool){
        XXXXBaseAdManager.updateAdSession(forcibly: forStartup)
    }
    
    //override me to use subclassed adContainer
    open func getAdContainer(frame:CGRect)->XXXXAdContainer{
        return XXXXAdContainer(frame: frame)
    }
    
    //puts ad in XXXXAdContainer. constrained to center. distinction added if necessary
    public func wrapAdInContainer(ad:UIView, withDistinctionType type:AdDistinctionType)->XXXXAdContainer{
        let distinctionHeight:CGFloat = type == .none ? 0 : type == .subtle ? 20 : 10
        let background:XXXXAdContainer = self.getAdContainer(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: ad.layer.frame.size.height + distinctionHeight))
        background.translatesAutoresizingMaskIntoConstraints = false
        ad.translatesAutoresizingMaskIntoConstraints = false
        background.backgroundColor = UIColor.webmdLightGrayBackgroundColor()
        background.addSubview(ad)
        background.tag = ad.tag
        background.ad = ad
        ad.setContentCompressionResistancePriority(1000, for: .horizontal)
        var bottomPadding:CGFloat = 0
        var top:NSLayoutConstraint
        if type != .none{
            let distinction = self.getDistinction(ofType: type)
            background.addSubview(distinction)
            let disTop = NSLayoutConstraint(item: distinction, attribute: .top, relatedBy: .equal, toItem: background, attribute: .top, multiplier: 1, constant: 0)
            let disLeading = NSLayoutConstraint(item: distinction, attribute: .leading, relatedBy: .equal, toItem: background, attribute: .leading, multiplier: 1, constant: 0)
            let disTrail = NSLayoutConstraint(item: distinction, attribute: .trailing, relatedBy: .equal, toItem: background, attribute: .trailing, multiplier: 1, constant: 0)
            distinction.updateConstraintsIfNeeded()
            background.addConstraints([disTop,disLeading,disTrail])
            background.updateConstraintsIfNeeded()
            top = NSLayoutConstraint(item: ad, attribute: .top, relatedBy: .equal, toItem: distinction, attribute: .bottom, multiplier: 1, constant: 0)
            bottomPadding = type == .subtle ? distinction.layer.frame.size.height : 0
        } else {
            top = NSLayoutConstraint(item: ad, attribute: .top, relatedBy: .equal, toItem: background, attribute: .top, multiplier: 1, constant: 0)
        }
        let centerX = NSLayoutConstraint(item: ad, attribute: .centerX, relatedBy: .equal, toItem: background, attribute: .centerX, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: background, attribute: .bottom, relatedBy: .equal, toItem: ad, attribute: .bottom, multiplier: 1, constant: bottomPadding)
        background.addConstraints([centerX,bottom,top])
        background.updateConstraintsIfNeeded()
        background.setNeedsLayout()
        return background
    }
    
    private func getDistinction(ofType type:AdDistinctionType)->UILabel{
        let distinction:UILabel = UILabel()
        distinction.text = "ADVERTISEMENT"
        distinction.textAlignment = .center
        
        if type == .overt{
            distinction.font = UIFont.systemFont(ofSize: 8)
            distinction.textColor = UIColor.white
            distinction.backgroundColor = UIColor(hex: "454C4F")
        } else if type == .subtle{
            distinction.font = UIFont.systemFont(ofSize: 8)
            distinction.textColor = UIColor.black
            distinction.backgroundColor = UIColor.clear
        }
        distinction.sizeToFit()
        distinction.translatesAutoresizingMaskIntoConstraints = false
        return distinction
    }
    
    public func getBlankAd(size:CGSize = CGSize(width: 300, height: 60))->UIView{
        let view:UIView = UIView()
        view.backgroundColor = UIColor.red
        view.translatesAutoresizingMaskIntoConstraints = false
        let width = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: size.width)
        let height = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: size.height)
        
        let label = UILabel()
        label.textColor = UIColor.white
        label.text = "blankAd"
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        let centerX = NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        
        view.addSubview(label)
        view.addConstraints([width,height,centerX,centerY])
        view.updateConstraintsIfNeeded()
        view.layoutIfNeeded()
        return view
    }
    
    
    /*
     Parameter adView: XXXXAdContainer UIView subclass containing the ad. All ads returned by this class exist as subviews of this class
     Parameter toContainer: UIView that the ad is being added to.
     Parameter atLocation: Should constrain ad the top or bottom of above view. Usually top or bottom
     Parameter withConstant: Extra padding. If atLocation is top the padding will go on top. If atLocation is bottom padding will go on bottom
     Parameter shouldRemovePrevious: Should this method also remove all ads that already exist on container. Set false if multiple ads will go in the same view
 */
    public class func addAndConstrain(adView ad: XXXXAdContainer,toContainer container:UIView,atLocation location:NSLayoutAttribute, withConstant constant:CGFloat, shouldRemovePrevious shouldRemove:Bool = true){
        if shouldRemove{
            for eachSubview in container.subviews{
                if let ad = eachSubview as? XXXXAdContainer{
                    ad.removeFromSuperview()
                }
            }
        }

        container.addSubview(ad)
        let centerX = NSLayoutConstraint(item: ad, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: ad, attribute: .width, relatedBy: .equal, toItem: container, attribute: .width, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: ad, attribute: location, relatedBy: .equal, toItem: container, attribute: location, multiplier: 1, constant: constant)
        container.addConstraints([centerX,width,top])
        DispatchQueue.main.async {
            ad.updateConstraintsIfNeeded()
            container.updateConstraintsIfNeeded()
            container.layoutIfNeeded()
        }
    }
    
}
// Session manager
extension XXXXBaseAdManager{
    // Parameter forcibly: set true to assign new session number regardless of session timeout
    fileprivate class func updateAdSession(forcibly:Bool){
        let now:Date = Date()
        let lastLoggedIn:Date = XXXXBaseAdManager.getLastLoggedIn()
        let minutesElapsed:Int = Calendar.current.dateComponents([.minute], from: lastLoggedIn, to: now).minute ?? XXXXBaseAdManager.sessionTimeout+1
        if minutesElapsed > XXXXBaseAdManager.sessionTimeout || forcibly{
            XXXXBaseAdManager.resetAdSession()
        }
    }
    
    fileprivate class func setLoggedOut(){
        let now = Date()
        UserDefaults.standard.set(now, forKey: XXXXBaseAdManager.lastLoggedInKey)
        UserDefaults.standard.synchronize()
    }
    
    fileprivate class func getAdSessionCount()->Int{
        if let session:Int = UserDefaults.standard.object(forKey: XXXXBaseAdManager.sessionCountKey) as? Int{
            return session
        } else {
            return 1
        }
    }
    
    fileprivate class func getAdSession()->Int{
        if let session:Int = UserDefaults.standard.object(forKey: XXXXBaseAdManager.sessionKey) as? Int{
            return session
        } else {
            let newSession:Int = XXXXBaseAdManager.getNewSession()
            XXXXBaseAdManager.setAdSession(session: newSession)
            return newSession
        }
    }
    
    private class func setAdSession(session:Int){
        UserDefaults.standard.set(session, forKey: XXXXBaseAdManager.sessionKey)
        UserDefaults.standard.synchronize()
    }
    
    fileprivate class func resetAdSession(){
        let newSession:Int = XXXXBaseAdManager.getNewSession()
        XXXXBaseAdManager.setAdSession(session: newSession)
    }
    
    fileprivate class func resetAdSessionCount(){
        UserDefaults.standard.removeObject(forKey: XXXXBaseAdManager.sessionCountKey)
    }
    
    private class func getNewSession()->Int{
        //Reset sessionCount if kCFBundleVersionKey has changed
        objc_sync_enter(self)
        var s = 1
        let version = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
        if let session:Int = UserDefaults.standard.object(forKey: XXXXBaseAdManager.sessionCountKey) as? Int, let lastVersion = UserDefaults.standard.string(forKey: XXXXBaseAdManager.sessionVersionKey), version == lastVersion {
            s = session+1
        }
        UserDefaults.standard.set(s, forKey: XXXXBaseAdManager.sessionCountKey)
        UserDefaults.standard.set(Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String, forKey: XXXXBaseAdManager.sessionVersionKey)
        UserDefaults.standard.synchronize()
        objc_sync_exit(self)
        
        //Generate newAdSession
        return Int(arc4random_uniform(UInt32(XXXXBaseAdManager.totalAdSessions)))+1
    }
    
    private class func getLastLoggedIn()->Date{
        if let time = UserDefaults.standard.object(forKey: XXXXBaseAdManager.lastLoggedInKey) as? Date{
            return time
        }
        return Date()
    }
    
}

@objc public protocol XXXXAdContainerProtocol:class {
    func impression()
}

@objc open class XXXXAdContainer:UIView{
    public var didTrackImpression:Bool = false
    public var ad:UIView?
    
    open func trackImpression(){
        if let d = self as? XXXXAdContainerProtocol{
            d.impression()
        }
    }
}
