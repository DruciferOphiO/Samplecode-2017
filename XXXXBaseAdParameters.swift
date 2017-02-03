//  Created by McKinley, Andrew on 9/28/16.
//  Copyright © 2016 XXXXX. All rights reserved.
//

import UIKit

open class XXXXBaseAdParameters: NSObject {

/*
    This class manages parameters used by XXXXBaseAdManager. When XXXXBaseAdManager is subclassed, make a corresponding subclass of this to handle all the specific data needed by XXXXBaseAdManager (example: adUnitId and root view controller for DFP ads). Subclass this to utilize custom parameters and their logic. If custom parameters are used then override getContentParameters to return all necessary data. Calling super.getContentParameters() may be needed
 
*/
    
    //required
    public var rootVC:UIViewController!
    public var tag:Int!
    public var distinction:AdDistinctionType!
    public var sizes:[XXXXBaseAdSize]!
    public var customSizes:[CGSize]?
    
    //optional
    public var isHomepage:Bool!
    public var isSponsored:Bool!
    public var primaryId:String?
    public var secondaryIds:[String]?
    
    public var position:String?
    public var app:String?
    public var adSessionNumber:Int!
    public let positionKey = "pos"
    public let appKey = "app"
    public let sessionKey = "ses"
    public let operatingSysKey = "os"
    public var useCustomSizesExclusively:Bool = false
    
    
/*
    Parameter withRoot: Root view controller expecting ad
    Parameter size: Size of ad. This class can only be instantiated with one. Use includeSize and includeCustom for more. To use custom size only instantiate with arbitrary size, use includeCustomSize to for the custom size, and utalize useCustomSizesExclusively in subclass to return only the custom size
    Parameter tag: Use if necessary to differentiate ads. Recommend passing this number to XXXXAdContainer
    Parameter distinction: Label above ad "ADVERTISEMENT"
*/
    public init(withRoot vc:UIViewController,size:XXXXBaseAdSize, tag:Int, andDistiction distinction:AdDistinctionType) {
        super.init()
        self.rootVC = vc
        self.tag = tag
        self.distinction = distinction
        self.sizes = [size]
        self.adSessionNumber = XXXXBaseAdManager.getAdSessionNumber()
        self.isHomepage = false
        self.isSponsored = false
    }
    
    public func includeSize(size:XXXXBaseAdSize){
        self.sizes.append(size)
    }
    
    public func includeCustomSize(size:CGSize){
        if self.customSizes == nil {
            self.customSizes = [CGSize]()
        }
        self.customSizes?.append(size)
    }
    
    open func getContentParameters()->[String:String]{
        return self.getBaseParameters()
    }
    
    public func getBaseParameters()->[String:String]{
        var positionParamDic:[String:String] = [String:String]()
        if let pos = self.position{
            positionParamDic[self.positionKey] = pos
        }
        
        if let app = self.app{
            positionParamDic[self.appKey] = app
        }
        
        positionParamDic[self.sessionKey] = self.adSessionNumber.description
        positionParamDic[self.operatingSysKey] = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "")
        return positionParamDic
    }
    
    open func getExclusionCategories()->[String]?{
        return nil
    }
}
