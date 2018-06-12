//
//  VendorMapViewController.swift
//  Savour
//
//  Created by Chris Patterson on 10/23/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase
import FirebaseStorage
import GeoFire

fileprivate var vendors = [VendorData]()

class VendorMapViewController: UIViewController{

    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var listView: UIView!
    
    var vendorList = Dictionary<String,VendorData>()

    var listVC: listViewController!
    var mapVC: mapViewController!
    var ref: DatabaseReference!
    var locationManager: CLLocationManager!
    var distanceFilter = 50.0
    var dealsData: DealsData!
    var vendorsData: VendorsData!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listVC.parentView = self
        if segControl.selectedSegmentIndex == 0 {
            showList()
        }
        else if segControl.selectedSegmentIndex == 1 {
            showMap()
        }
        locationManager = CLLocationManager()
        requestLocationAccess()
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        //callback to know when the user accepts or denies location services
        if status == CLAuthorizationStatus.denied {
            locationDisabled()
        } else if status == .authorizedAlways || status == .authorizedWhenInUse  {
            locationEnabled()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //dont call requestlocation or the user can get into a loop here
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.denied {
            locationDisabled()
        } else if status == .authorizedAlways || status == .authorizedWhenInUse  {
            locationEnabled()
        }
    }

    func requestLocationAccess() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationEnabled()
        case .denied, .restricted:
            locationDisabled()
        default:
            performSegue(withIdentifier: "promptSegue", sender: "vendors")
        }
    }
    
    func locationDisabled(){
        self.listVC.searchBar.isHidden = true
        listVC.listTable.isHidden = true
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy)
        label.text = "To use this feature, you must turn on location in:\n\n Settings -> Savour -> Location"
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        label.textColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tag = 100
        self.listView.addSubview(label)
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leadingMargin, multiplier: 1.0, constant: 5.0))
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1.0, constant: -5.0))
        NSLayoutConstraint.activate(constraints)
    }
    
    func locationEnabled(){
        DispatchQueue.main.async {
            if let _ = self.listView.viewWithTag(100){
                self.listView.viewWithTag(100)?.removeFromSuperview()
            }
            self.locationManager!.startUpdatingLocation()
            self.listVC.searchBar.isHidden = false
            self.getData()
        }
    }
    
    func showList(){
        listView.isHidden = false
        mapView.isHidden = true
    }
    
    func showMap(){
        listView.isHidden = true
        mapView.isHidden = false
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "list"{
            listVC = segue.destination as! listViewController
        }
        if segue.identifier == "map"{
            mapVC = segue.destination as! mapViewController
        }
        if segue.identifier == "vendor"{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            let vc = segue.destination as! RestaurantViewController
            vc.thisVendor = vendorList[(sender as? String)!]
            vc.dealsData = self.dealsData
        }
//        if segue.identifier == "promptSegue"{
//            let vc = segue.destination as! LocationViewController
//            vc.sender = "map"
//        }
    }
    
    @IBAction func segmentChanged(_ sender: Any) {
        if segControl.selectedSegmentIndex == 0 {
            showList()
        }
        if segControl.selectedSegmentIndex == 1{
            showMap()
        }
    }
    
    @objc func refreshData() {
       getData()
    }
    
    func getData(){
        vendorsData.updateDistances(location: locationManager.location!)
        vendors = vendorsData.getVendors()
        for rest in vendors{
            self.vendorList[rest.id!] = rest
        }
        if vendors.count <= 0 {
//                self.listVC.noRest.isHidden = false
        }else if vendors.count > 0{
            self.mapVC.flag = 1
            vendors.sort(by: { (r1, r2) -> Bool in
                if r1.distanceMiles! < r2.distanceMiles!{
                    return true
                }else{
                    return false
                }
            })
            self.mapVC.makeAnnotations()
            self.listVC.delegateTable()
            self.listVC.listTable.reloadData()
        }
    }
}

class mapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    var regionRadius: CLLocationDistance = 1000
    var locationManager: CLLocationManager!
    var flag = 1
    
    @IBOutlet weak var center: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        center.layer.cornerRadius = center.frame.height/2
        let image = center.imageView?.image!.withRenderingMode(.alwaysTemplate)
        center.tintColor = UIColor.white
        center.imageView?.tintColor = UIColor.white
        center.setImage(image, for: UIControlState.normal)
        center.layer.shadowRadius = 2
        center.layer.shadowOpacity = 0.5
        center.layer.shadowOffset = CGSize(width: 6, height: 6)

        locationManager = CLLocationManager()
        locationManager!.delegate = self
        
        // set initial location
        let initialLocation = CLLocation(latitude: 44.977289, longitude: -93.229499)
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            let viewRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 1000, 1000)
            mapView.setRegion(viewRegion, animated: false)
            DispatchQueue.main.async {
                self.locationManager!.startUpdatingLocation()
            }
            mapView.showsUserLocation = true
        }
    }
    @IBAction func centerMap(_ sender: Any) {
        let viewRegion = MKCoordinateRegionMakeWithDistance((locationManager.location?.coordinate)!, 1000, 1000)
        mapView.setRegion(viewRegion, animated: true)
    }
    
    func makeAnnotations(){
        self.mapView.removeAnnotations(self.mapView.annotations)
        for i in 0..<vendors.count{
            let annotation = vendorAnnotation(title: vendors[i].name!, coordinate: (vendors[i].location?.coordinate)!, rID: vendors[i].id!)
            self.mapView.addAnnotation(annotation)
        }
        self.mapView.delegate = self
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "vendor"
        
        if annotation is vendorAnnotation {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation
                return annotationView
            } else {
                let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:identifier)
                annotationView.isEnabled = true
                annotationView.canShowCallout = true
                
                let btn = UIButton(type: .detailDisclosure)
                annotationView.rightCalloutAccessoryView = btn
                return annotationView
            }
        }
        return nil
    }
        
    internal func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let location = view.annotation as! vendorAnnotation
        let placeRID = location.rID
        let parent = self.parent as! VendorMapViewController
        parent.performSegue(withIdentifier: "vendor", sender: placeRID)
    }
    
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if flag == 1{
            mapView.centerCoordinate = userLocation.location!.coordinate
            flag = 0
        }
    }
    
    
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

class vendorAnnotation: NSObject, MKAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var rID: String
    
    init(title: String, coordinate: CLLocationCoordinate2D, rID: String) {
        self.title = title
        self.coordinate = coordinate
        self.rID = rID
    }
}



class listViewController: UIViewController, UITableViewDelegate,UITableViewDataSource, UISearchBarDelegate{
    var storageRef: Storage!
    @IBOutlet weak var listTable: UITableView!
    var myVendors = [VendorData]()
    @IBOutlet weak var searchBar: UISearchBar!
    var statusBar: UIView!
    @IBOutlet weak var noRest: UILabel!
    private let refreshControl = UIRefreshControl()
    var parentView: VendorMapViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storageRef = Storage.storage()
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            listTable.refreshControl = refreshControl
        } else {
            listTable.addSubview(refreshControl)
        }
        // Configure Refresh Control
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Vendors", attributes: [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)])
        refreshControl.tintColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        refreshControl.addTarget(self, action: #selector(self.refreshingData(_:)), for: .valueChanged)
        setupSearchBar()
    }
    
    @objc private func refreshingData(_ sender: Any){
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        searchBar.text = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { () -> Void in
            let parent = self.parent as! VendorMapViewController
            parent.refreshData()
            self.myVendors = vendors
            self.listTable.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
    }
    
  
    func delegateTable(){
        myVendors = vendors
        listTable.dataSource = self
        listTable.delegate = self
        listTable.reloadData()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y>0{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
            }, completion: nil)
        }
        else{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if myVendors.count < 1 {
            self.noRest.isHidden = false
        }else{
            self.noRest.isHidden = true
        }
        return myVendors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vendor", for: indexPath) as! vendorCell
        cell.vendor = myVendors[indexPath.row]

        let photo = cell.vendor.photo!
        if photo != ""{

            
            // UIImageView in your ViewController
            let imageView: UIImageView = cell.rImg
            
            // Placeholder image
            let placeholderImage = UIImage(named: "placeholder.jpg")
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: URL(string: photo), placeholderImage: placeholderImage)
        }
        cell.rName.text = cell.vendor.name
        if let distance = cell.vendor.distanceMiles{
            cell.distanceTxt.text = String(format:"%.1f", distance) + " miles away"
        }
        else{
            cell.distanceTxt.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath) as! vendorCell
        let parent = self.parent as! VendorMapViewController
        parent.performSegue(withIdentifier: "vendor", sender: cell.vendor.id)
    }
    //SearchBar functions
    func setupSearchBar(){
        // Setup the Search Controller
        searchBar.showsCancelButton = false
        searchBar.placeholder = "Search Vendors"
        searchBar.tintColor = UIColor.white
        searchBar.delegate = self
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text! == "" {
            myVendors = vendors
        } else {
            // Filter the results
            myVendors = vendors.filter { ($0.name?.lowercased().contains(searchBar.text!.lowercased()))! }
        }
        listTable.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        if searchBar.text! == "" {
            myVendors = vendors
        } else {
            // Filter the results
            myVendors = vendors.filter { ($0.name?.lowercased().contains(searchBar.text!.lowercased()))! }
        }
        listTable.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //searchBar.resignFirstResponder()
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
    }
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

}

class vendorCell: UITableViewCell{
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var insetView: UIView!
    @IBOutlet weak var rName: UILabel!
    var vendor: VendorData!
    @IBOutlet weak var distanceTxt: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.insetView.layer.cornerRadius = 10
        self.insetView.clipsToBounds = true
    }

}
