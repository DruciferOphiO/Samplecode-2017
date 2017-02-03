//  Created by McKinley, Andrew on 7/18/16.
//  Copyright © 2016 McKinley, Andrew. All rights reserved.
//

import UIKit
import MapKit

@objc protocol XXXXXXMapViewDelegate {
    @objc optional func didSelectAnnotation(_ _dataObjectXXXXXXDirectoryBaseObject)
    @objc optional func updateWithNewLocation(_ _location:CLLocationCoordinate2D, inCity _city:String?, state _state:String?, andZip _zip:String?)
    @objc optional func mapDidFinishDragging()
}

class XXXXXXMapView: MKMapView {
    
    var shouldShowCalloutAccessoryView:Bool = true
    let annotationId = "pin"
    var currentCallout:XXXXXXCalloutView?
    var currentAnnotation:MKAnnotationView?
    var shouldAddCallout:Bool = false
    var annotationDelegate:XXXXXXMapViewDelegate?
    var dataObjects:[XXXXXXDirectoryBaseObject] = [XXXXXXDirectoryBaseObject]()
    var hasSetInitialRegion:Bool = false
	var didFinishRenderingMapFullyRendered: ((_ mapView: MKMapView, _ fullyRendered: Bool) -> ())?
	
    override func awakeFromNib() {
        super.awakeFromNib()
        self.delegate = self
        self.showsUserLocation = true
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
    
    func addDataObject(_ _object:XXXXXXDirectoryBaseObject){
        self.dataObjects.append(_object)
    }
    
    func clearData(){
        self.dataObjects.removeAll()
        self.removeAnnotations(self.annotations)
    }
    
    func shouldGetNewLocation(){
        self.clearData()
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: self.region.center.latitude, longitude: self.region.center.longitude)) { (_placemark, error) in
            if let location = _placemark?[0]{
                if let address = location.addressDictionary{
                    self.annotationDelegate?.updateWithNewLocation?(self.region.center, inCity: address["City"] as? String, state: address["State"] as? String, andZip: address["ZIP"] as? String)
                }
            }
        }
    }
    
	func updateAnnotations(){
        var annotations:[XXXXXXDirectoryAnnotation] = [XXXXXXDirectoryAnnotation]()
        var locations:[CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        for eachDataObject in self.dataObjects{

            if let physicianObject = eachDataObject as? XXXXXXDirectoryPhysicianObject{
                if let array:[XXXXXXDirectoryPracticeLocationObject] = physicianObject.practiceLocations , array.count > 0{
                    if let firstLocation = array[0].profile?.annotation{
                        firstLocation.indexTag = self.dataObjects.index(of: eachDataObject)!
                        annotations.append(firstLocation)
                        locations.append(firstLocation.coordinate)
                    }
                }
            } else if let practiceObject = eachDataObject as? XXXXXXDirectoryPracticeLocationObject{
                if let annotation = practiceObject.profile?.annotation{
                    annotation.indexTag = self.dataObjects.index(of: eachDataObject)!
                    annotations.append(annotation)
                    locations.append(annotation.coordinate)
                }
            } else if let practiceObject = eachDataObject as? XXXXXXDirectoryPracticeObject{
				let array:[XXXXXXDirectoryPracticeLocationObject] = practiceObject.practiceLocations
				if array.count > 0{
                    if let firstLocation = array[0].profile?.annotation{
                        firstLocation.indexTag = self.dataObjects.index(of: eachDataObject)!
                        annotations.append(firstLocation)
                        locations.append(firstLocation.coordinate)
                    }
                }
            } else if let hospitalObject = eachDataObject as? XXXXXXDirectoryHospitalObject{
                if let annotation = hospitalObject.profile?.annotation{
                    annotation.indexTag = self.dataObjects.index(of: eachDataObject)!
                    annotations.append(annotation)
                    locations.append(annotation.coordinate)
                }
            } else if let pharmacyObject = eachDataObject as? XXXXXXirectoryPharmacyObject{
                if let annotation = pharmacyObject.profile?.annotation{
                    annotation.indexTag = self.dataObjects.index(of: eachDataObject)!
                    annotations.append(annotation)
                    locations.append(annotation.coordinate)
                }
            }
        }
        if !self.hasSetInitialRegion{
            self.setRegion(self.getCenterCoord(locations))
        }
        self.addAnnotations(annotations)
    }
	
    private func setRegion(_ location:CLLocationCoordinate2D){
        let locationPoint = MKMapPointForCoordinate(location)
        var zoomRect:MKMapRect = MKMapRectMake(locationPoint.x, locationPoint.y, 0.1, 0.1)
        
        for eachDataObject in self.dataObjects {
            if let physicianObject = eachDataObject as? XXXXXXDirectoryPhysicianObject{
                if let array:[XXXXXXDirectoryPracticeLocationObject] = physicianObject.practiceLocations , array.count > 0{
                    if let firstLocation = array[0].profile?.annotation{
                        self.addAnnotation(annotation: firstLocation, toZoomRect: &zoomRect)
                    }
                }
            }else if let practiceObject = eachDataObject as? XXXXXXDirectoryPracticeLocationObject{
                if let annotation = practiceObject.profile?.annotation{
                    self.addAnnotation(annotation: annotation, toZoomRect: &zoomRect)
                }
            } else if let practiceObject = eachDataObject as? XXXXXXDirectoryPracticeObject{
                let array:[XXXXXXDirectoryPracticeLocationObject] = practiceObject.practiceLocations
				if array.count > 0 {
					if let firstLocation = array[0].profile?.annotation{
						self.addAnnotation(annotation: firstLocation, toZoomRect: &zoomRect)
					}
                }
            } else if let hospitalObject = eachDataObject as? XXXXXXDirectoryHospitalObject{
                if let annotation = hospitalObject.profile?.annotation{
                    self.addAnnotation(annotation: annotation, toZoomRect: &zoomRect)
                }
            } else if let pharmacyObject = eachDataObject as? XXXXXXDirectoryPharmacyObject{
                if let annotation = pharmacyObject.profile?.annotation{
                    self.addAnnotation(annotation: annotation, toZoomRect: &zoomRect)
                }
            }
        }
        self.setVisibleMapRect(zoomRect, animated: false)
        self.hasSetInitialRegion = true
    }
    
    private func addAnnotation(annotation:XXXXXXDirectoryAnnotation, toZoomRect _zoomRect:inout MKMapRect){
        let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
        let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1)
        _zoomRect = MKMapRectUnion(_zoomRect, pointRect)
    }
    
    fileprivate func constraintCallout(_ callout:XXXXXXCalloutView, toAnnotation annotation:UIView){
        for eachConstraint in self.constraints{
            self.removeConstraint(eachConstraint)
        }
        
        let bottom = NSLayoutConstraint(item: callout, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: annotation.frame.origin.y-5)//TODO put in config
        let centerX = NSLayoutConstraint(item: callout, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: self.calculateCenterXOffset(ofCallout: callout, fromAnnotation: annotation))
        self.addConstraints([centerX,bottom])
        self.updateConstraints()
        self.layoutIfNeeded()
    }
    
    private func calculateCenterXOffset(ofCallout _callout:XXXXXXCalloutView, fromAnnotation _annotation:UIView)->CGFloat{
        let mapWidth: CGFloat = self.frame.size.width
        let accessoryWidth:CGFloat = _callout.frame.size.width
        let annotationCenter:CGFloat = _annotation.frame.origin.x + _annotation.frame.size.width/2
        let accessoryLeading:CGFloat = annotationCenter - accessoryWidth/2
        if accessoryLeading < 0 {
            return 0
        }
        if (accessoryLeading + accessoryWidth) > mapWidth{
            return mapWidth - accessoryWidth
        }
        
        return accessoryLeading
    }
    
    fileprivate func addCallout(toAnnotation _annotation:MKAnnotationView){
        if let view = self.currentCallout{
            view.removeFromSuperview()
        }
        if let annotation:XXXXXXDirectoryAnnotation = _annotation.annotation as? XXXXXXDirectoryAnnotation{
            let customAnnotation:XXXXXXDirectoryAnnotation = annotation as XXXXXXDirectoryAnnotation
            let calloutView:XXXXXXCalloutView = XXXXXXCalloutView()
            calloutView.translatesAutoresizingMaskIntoConstraints = false
            let unwrappedData = self.dataObjects[customAnnotation.indexTag]
            calloutView.updateWithAnnotation(unwrappedData)
            calloutView.delegate = self
            annotation.isSelected = true
            if self.hasRoomAboveAnnotation(_annotation, forCallout: calloutView){
                self.addSubview(calloutView)
                self.constraintCallout(calloutView, toAnnotation: _annotation)
                self.currentAnnotation = _annotation
                self.currentCallout = calloutView
            } else {
                self.dragMapBeforeAddingCallout(calloutView, forAnnotation: _annotation)
            }
            
        }
    }
    
    private func hasRoomAboveAnnotation(_ _annotation:MKAnnotationView, forCallout _view:XXXXXXCalloutView)->Bool{
        if _annotation.frame.origin.y < _view.frame.size.height{
            return false
        }
        return true
    }
    
    private func dragMapBeforeAddingCallout(_ _callout:XXXXXXCalloutView, forAnnotation _annotation:MKAnnotationView){
        if let annotation = _annotation.annotation{
            self.shouldAddCallout = true
            self.currentCallout = _callout
            self.currentAnnotation = _annotation
            self.setCenter(annotation.coordinate, animated: true)
        }
    }
    
    private func degreesToRadians(_ degrees: Double) -> Double { return degrees * M_PI / 180.0 }
    private func radiansToDegrees(_ radians: Double) -> Double { return radians * 180.0 / M_PI }
    
    private func getCenterCoord(_ LocationPoints: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D{
        
        var x:Double = 0.0;
        var y:Double = 0.0;
        var z:Double = 0.0;
        
        for points in LocationPoints {
            
            let lat = self.degreesToRadians(Double(points.latitude));
            let long = self.degreesToRadians(Double(points.longitude));
            
            x += cos(lat) * cos(long);
            y += cos(lat) * sin(long);
            z += sin(lat);
        }
        
        x = x / Double(LocationPoints.count);
        y = y / Double(LocationPoints.count);
        z = z / Double(LocationPoints.count);
        
        let resultLong = atan2(y, x);
        let resultHyp = sqrt(x * x + y * y);
        let resultLat = atan2(z, resultHyp);
        let result = CLLocationCoordinate2D(latitude: CLLocationDegrees(self.radiansToDegrees(Double(resultLat))), longitude: CLLocationDegrees(self.radiansToDegrees(Double(resultLong))));
        return result;
    }
    
}


extension XXXXXXMapView: MKMapViewDelegate {
	
	func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
		if let block = didFinishRenderingMapFullyRendered {
			block(mapView, fullyRendered)
		} else {
			
		}
	}
	
    internal func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        
        if let annotation:XXXXXXDirectoryAnnotation = annotation as? XXXXXXDirectoryAnnotation{
            if let title = annotation.title{
                let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: title)  ?? MKAnnotationView(annotation: annotation, reuseIdentifier: self.annotationId)
                annotationView.canShowCallout = false
                annotationView.image = XXXXXXDirectory_StyleKit.imageOfPin()
                return annotationView
            }
        }
        return nil
    }
    
    internal func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        
        let viewToCallout:MKAnnotationView = mapView.view(for: self.nextAnnotationConsideringOverlap(selectedAnnotation: view.annotation!))!
        
        if self.shouldShowCalloutAccessoryView{
            self.addCallout(toAnnotation: viewToCallout)
        }
        
        
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    private func getOverlappingAnnotations(annotation:MKAnnotation)->[MKAnnotation]{
        var array:[MKAnnotation] = [MKAnnotation]()
        let selectedLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        for eachAnnotation in self.annotations{
            let eachLocation = CLLocation(latitude: eachAnnotation.coordinate.latitude, longitude: eachAnnotation.coordinate.longitude)
            
            if selectedLocation.distance(from: eachLocation) == 0{
				#if DEBUG
					print(eachAnnotation.title ?? "")
				#endif
                array.append(eachAnnotation)
            }
        }
        
        return array
    }
    
    private func nextAnnotationConsideringOverlap(selectedAnnotation:MKAnnotation)->MKAnnotation{
        let overlapingAnnotations = self.getOverlappingAnnotations(annotation: selectedAnnotation)
        
        if overlapingAnnotations.count > 1{
            for eachAnnotation in overlapingAnnotations{
                if let castedAnnotation = eachAnnotation as? XXXXXXDirectoryAnnotation{
                    if !castedAnnotation.isSelected{
                        return eachAnnotation
                    }
                    
                }
            }
        }
        self.clearPreviousSelections()
        return selectedAnnotation
    }
    
    private func clearPreviousSelections(){
        for eachAnnotation in self.annotations{
            if let castedAnnotation = eachAnnotation as? XXXXXXDirectoryAnnotation{
                castedAnnotation.isSelected = false
            }
        }
    }
    
    internal func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool){
        if let view = self.currentCallout{
            view.removeFromSuperview()
        }
    }
    
    internal func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
        if let callout = self.currentCallout, let annotation = self.currentAnnotation , self.shouldAddCallout{
            self.shouldAddCallout = false
            self.addSubview(callout)
            self.constraintCallout(callout, toAnnotation: annotation)
        }
        
        if self.hasSetInitialRegion{
           self.annotationDelegate?.mapDidFinishDragging?()
        }
    }
    
    internal func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let visibleRect = mapView.annotationVisibleRect
        
        for view:MKAnnotationView in views{
            if !(view.annotation is MKUserLocation){
                let endFrame:CGRect = view.frame
                var startFrame:CGRect = endFrame
                startFrame.origin.y = visibleRect.origin.y - startFrame.size.height
                view.frame = startFrame;
                
                UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseIn, animations: { 
                    view.frame = endFrame;
                }, completion: nil)
            }
        }
    }
}

extension XXXXXXMapView: XXXXXXCalloutViewDelegate{
    func didSelectCallout(withData _dataObject:XXXXXXDirectoryBaseObject){
        self.annotationDelegate?.didSelectAnnotation?(_dataObject)
    }
}
