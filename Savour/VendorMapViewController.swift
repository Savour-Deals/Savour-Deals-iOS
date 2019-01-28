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
import LCUIComponents

fileprivate var vendors = [VendorData]()

class VendorMapViewController: UIViewController{

    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var listView: UIView!
    var searchbarData: [LCTuple<Double>] = []
    
    var vendorList = Dictionary<String,VendorData>()

    @IBOutlet weak var distanceFilterBtn: UIButton!
    var listVC: listViewController!
    var mapVC: mapViewController!
    var ref: DatabaseReference!
    var locationManager: CLLocationManager!
    var dealsData: DealsData!
    var vendorsData: VendorsData!
    var sv: UIView!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sv = UIViewController.displaySpinner(onView: self.view, color: #colorLiteral(red: 0.2862745098, green: 0.6705882353, blue: 0.6666666667, alpha: 1))

        let image = UIImage(named:"distance")?.withRenderingMode(.alwaysTemplate)
        distanceFilterBtn.setImage(image, for: .normal)
        distanceFilterBtn.tintColor = UIColor.white
        
        for i in 1...10 {
            searchbarData.append((key: Double(i*5), value: "\(i*5) miles"))
        }
        for i in 1...10 {
            searchbarData.append((key: Double(i*100), value: "\(i*100) miles"))
        }

        //Setup what view we see
        listVC.parentView = self
        if segControl.selectedSegmentIndex == 0 {
            showList()
        }
        else if segControl.selectedSegmentIndex == 1 {
            showMap()
        }
        
        locationManager = CLLocationManager()
        
        //Allow us to refresh when opened from background
        NotificationCenter.default.addObserver(self, selector: #selector(self.requestLocationAccess), name:UIApplication.willEnterForegroundNotification, object: nil)

    }
    
    deinit { //Remove background observer
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if dealsData != nil && vendorsData != nil{
            locationEnabled()
        }else{
            requestLocationAccess()
        }
    }

    //Location status fucntions
    @objc func requestLocationAccess() {
        checkLocationStatus(status: CLLocationManager.authorizationStatus())
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        //callback to know when the user accepts or denies location services
        checkLocationStatus(status: status)
    }

    
    @IBAction func distanceFilterClicked(_ sender: Any) {
        let popover = LCPopover<Double>(for: distanceFilterBtn, title: "Search Radius") { tuple in
            // Use of the selected tuple
            guard let value = tuple?.key else { return }
            geoFireRadius = value
            self.dealsData.updateRadius(rad: value)
            self.vendorsData.updateRadius(rad: value)
            self.getData()
        }
        // Assign data to the dataList
        popover.dataList = searchbarData
        popover.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        popover.borderColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        popover.borderWidth = 2
        popover.titleColor = .white
        popover.textColor = .black
        // Present the popover
        present(popover, animated: true, completion: nil)
    }
    
    func checkLocationStatus(status: CLAuthorizationStatus){
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { // Display message if loading is slow
                if !self.vendorsData.isComplete(){
                    Toast.showNegativeMessage(message: "Vendors seem to be taking a while to load. Check your internet connection to make sure you're online.")
                }
            }
            dealsData = DealsData(radiusMiles: geoFireRadius)
            vendorsData = VendorsData(radiusMiles: geoFireRadius)
//            DispatchQueue.global(qos: .background).async {
                self.dealsData.startDealUpdates(completion: { (success) in
                    if self.vendorsData.isComplete() && self.dealsData.isComplete(){
                        self.locationEnabled()
                    }
                })
//            }
//            DispatchQueue.global(qos: .background).async {
                self.vendorsData.startVendorUpdates(completion: { (success) in
                    if self.vendorsData.isComplete() && self.dealsData.isComplete(){
                        self.locationEnabled()
                    }
                })
//            }
        default:
            locationDisabled()
        }
    }
    
    func locationDisabled(){
        self.listVC.searchBar.isHidden = true
        listVC.listTable.isHidden = true
        self.listVC.locationText.isHidden = false
        UIViewController.removeSpinner(spinner: self.sv)
    }
    
    @objc func locationEnabled(){
        UIViewController.removeSpinner(spinner: self.sv)
        self.dealsData.updateRadius(rad: geoFireRadius)
        self.vendorsData.updateRadius(rad: geoFireRadius)
        DispatchQueue.main.async {
            if let _ = self.listView.viewWithTag(100){
                self.listView.viewWithTag(100)?.removeFromSuperview()
            }
            self.listVC.locationText.isHidden = true
            self.listVC.listTable.isHidden = false
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
            listVC = segue.destination as? listViewController
        }
        if segue.identifier == "map"{
            mapVC = segue.destination as? mapViewController
        }
        if segue.identifier == "vendor"{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            let vc = segue.destination as! RestaurantViewController
            vc.thisVendor = vendorList[(sender as? String)!]
            vc.dealsData = self.dealsData
        }
    }
    
    @IBAction func segmentChanged(_ sender: Any) {
        if segControl.selectedSegmentIndex == 0 {
            showList()
        }
        if segControl.selectedSegmentIndex == 1{
            showMap()
        }
    }
    
    func refreshData() {
       getData()
    }
    
    func getData(){
        if let location = locationManager.location{
            if vendorsData != nil{
                vendorsData.updateDistances(location: location)
            }
        }
        vendors = self.vendorsData.getVendors()
        for rest in vendors{
            self.vendorList[rest.id!] = rest
        }
        if vendors.count <= 0 {
            self.listVC.noRest.isHidden = false
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
            self.listVC.myVendors = vendors
            self.listVC.delegateTable()
        }
        self.listVC.listTable.reloadData()
    }
}

class mapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    var regionRadius: CLLocationDistance = 4000
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
        center.setImage(image, for: UIControl.State.normal)
        center.layer.shadowRadius = 2
        center.layer.shadowOpacity = 0.5
        center.layer.shadowOffset = CGSize(width: 6, height: 6)

        locationManager = CLLocationManager()
        locationManager!.delegate = self
        
        // set initial location
        let initialLocation = CLLocation(latitude: 44.977289, longitude: -93.229499)
        let status = CLLocationManager.authorizationStatus()
        if  status == .authorizedWhenInUse || status == .authorizedAlways {
            let viewRegion = MKCoordinateRegion.init(center: initialLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            mapView.setRegion(viewRegion, animated: false)
            DispatchQueue.main.async {
                self.locationManager!.startUpdatingLocation()
            }
            mapView.showsUserLocation = true
        }
    }
    
    @IBAction func centerMap(_ sender: Any) {
        if let _ = locationManager.location?.coordinate{
            let viewRegion = MKCoordinateRegion.init(center: (locationManager.location?.coordinate)!, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            mapView.setRegion(viewRegion, animated: true)
        }
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
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
                                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
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
    @IBOutlet weak var locationText: UILabel!
    var parentView: VendorMapViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storageRef = Storage.storage()
        self.locationText.text = "To use this feature, you must turn on location in:\n\n Settings -> Savour -> Location"
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            listTable.refreshControl = refreshControl
        } else {
            listTable.addSubview(refreshControl)
        }
        // Configure Refresh Control
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Vendors", attributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)])
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
            self.refreshControl.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView
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
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIView.AnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
            }, completion: nil)
        }
        else{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIView.AnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.myVendors = vendors
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
        }else{
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
