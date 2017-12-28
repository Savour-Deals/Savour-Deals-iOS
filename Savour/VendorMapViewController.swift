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

var restaurants = [restaurant]()

class VendorMapViewController: UIViewController{

    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var listView: UIView!
    var listVC: listViewController!
    var mapVC: mapViewController!
    var ref: DatabaseReference!
    var locationManager: CLLocationManager!
    var distanceFilter = 50.0

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if segControl.selectedSegmentIndex == 0 {
            showList()
        }
        else if segControl.selectedSegmentIndex == 1 {
            showMap()
        }
        locationManager = CLLocationManager()

        requestLocationAccess()
        //locationManager!.delegate = self
        
        // set initial location
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            //self.getRestaurants()

            DispatchQueue.main.async {
                self.locationManager!.startUpdatingLocation()
            }
        }
        else{
            self.listVC.searchBar.isHidden = true
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            self.getRestaurants()
            self.listView.viewWithTag(100)?.removeFromSuperview()
            DispatchQueue.main.async {
                self.locationManager!.startUpdatingLocation()
            }
        }
    }

    func requestLocationAccess() {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return
            
        case .denied, .restricted:
            print("location access denied")
            
        default:
            locationManager.requestWhenInUseAuthorization()
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
        if segue.identifier == "restaurant"{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            let vc = segue.destination as! DetailsViewController
            vc.rID = sender as? String
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
    func getRestaurants(){
        let group = DispatchGroup()
        ref = Database.database().reference().child("Restaurants")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            restaurants.removeAll()
            for entry in snapshot.children {
                group.enter()
                let snap = entry as! DataSnapshot
                let temp = restaurant(snap: snap, ID: snap.key)
                let geoCoder = CLGeocoder()
                geoCoder.geocodeAddressString(temp.address!) { (placemarks, error) -> Void in
                    if((error) != nil){
                        print("Error", error ?? "")
                    }
                    if let placemark = placemarks?.first {
                        temp.coordinates = placemark.location!.coordinate
                        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                            let Location = CLLocation.init(latitude: (self.locationManager.location?.coordinate.latitude)!, longitude: (self.locationManager.location?.coordinate.longitude)!)
                            temp.distanceMiles = (placemark.location?.distance(from: Location))!/1609.344
                            if temp.distanceMiles! < self.distanceFilter{
                                restaurants.append(temp)
                            }
                        }
                        else{
                            restaurants.append(temp)
                        }
                        restaurants.sort { CGFloat($0.distanceMiles!) < CGFloat($1.distanceMiles!) }
                    }
                    group.leave()
                }
                
            }
            group.notify(queue: DispatchQueue.main) {
                if restaurants.count < 1 {
                    let label = UILabel()
                    label.textAlignment = NSTextAlignment.center
                    label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy)
                    label.text = "No restaurants are nearby."
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
                }else if restaurants.count > 0{
                    self.listView.viewWithTag(100)?.removeFromSuperview()
                    self.mapVC.makeAnnotations()
                    self.listVC.delegateTable()
                    self.listVC.listTable.reloadData()
                    self.mapVC.flag = 1
                }
            }
        })
    }
}

class mapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    var regionRadius: CLLocationDistance = 1000
    var locationManager: CLLocationManager!
    var flag = 1
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func makeAnnotations(){
        self.mapView.removeAnnotations(self.mapView.annotations)
        for i in 0..<restaurants.count{
            let annotation = restaurantAnnotation(title: restaurants[i].restrauntName!, coordinate: restaurants[i].coordinates!, rID: restaurants[i].restrauntID!)
            self.mapView.addAnnotation(annotation)
        }
        self.mapView.delegate = self
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "restaurant"
        
        if annotation is restaurantAnnotation {
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
        let location = view.annotation as! restaurantAnnotation
        let placeRID = location.rID
        let parent = self.parent as! VendorMapViewController
        parent.performSegue(withIdentifier: "restaurant", sender: placeRID)
    }
    
    
    func mapView(_ mapView: MKMapView, didUpdate
        userLocation: MKUserLocation) {
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

class restaurantAnnotation: NSObject, MKAnnotation {
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
    var myRestaurants = [restaurant]()
    @IBOutlet weak var searchBar: UISearchBar!
    var statusBar: UIView!
    @IBOutlet weak var noRest: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storageRef = Storage.storage()
        setupSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
    }
    
  
    func delegateTable(){
        myRestaurants = restaurants
        listTable.dataSource = self
        listTable.delegate = self
        listTable.reloadData()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y>0{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                //self.navigationController?.setToolbarHidden(true, animated: true)
            }, completion: nil)
        }
        else{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                //self.navigationController?.setToolbarHidden(false, animated: true)
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if restaurants.count < 1 {
            self.noRest.isHidden = false
            self.listTable.isHidden = true
        }else{
            self.noRest.isHidden = true
            self.listTable.isHidden = false
        }
        return myRestaurants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "restaurant", for: indexPath) as! restaurantCell
        cell.restaurant = myRestaurants[indexPath.row]

        let photo = cell.restaurant.restrauntPhoto!
        if photo != ""{
            // Reference to an image file in Firebase Storage
            let storage = Storage.storage()
            let storageref = storage.reference(forURL: photo)
            
            // UIImageView in your ViewController
            let imageView: UIImageView = cell.rImg
            
            // Placeholder image
            let placeholderImage = UIImage(named: "placeholder.jpg")
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: storageref, placeholderImage: placeholderImage)
        }
        cell.rName.text = cell.restaurant.restrauntName
        if let distance = cell.restaurant.distanceMiles{
            cell.distanceTxt.text = String(format:"%.1f", distance) + " miles away"
        }
        else{
            cell.distanceTxt.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let parent = self.parent as! VendorMapViewController
        parent.performSegue(withIdentifier: "restaurant", sender: restaurants[indexPath.row].restrauntID)
    }
    //SearchBar functions
    func setupSearchBar(){
        // Setup the Search Controller
        searchBar.showsCancelButton = false
        searchBar.placeholder = "Search Restaurants"
        searchBar.tintColor = UIColor.white
        searchBar.delegate = self
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text! == "" {
            myRestaurants = restaurants
        } else {
            // Filter the results
            myRestaurants = restaurants.filter { ($0.restrauntName?.lowercased().contains(searchBar.text!.lowercased()))! }
        }
        listTable.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        if searchBar.text! == "" {
            myRestaurants = restaurants
        } else {
            // Filter the results
            myRestaurants = restaurants.filter { ($0.restrauntName?.lowercased().contains(searchBar.text!.lowercased()))! }
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

class restaurantCell: UITableViewCell{
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var insetView: UIView!
    @IBOutlet weak var rName: UILabel!
    var restaurant: restaurant!
    @IBOutlet weak var distanceTxt: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.insetView.layer.cornerRadius = 5
        self.insetView.clipsToBounds = true
    }

}


