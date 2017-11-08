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
            DispatchQueue.main.async {
                self.locationManager!.startUpdatingLocation()
            }
        }
        getRestaurants()
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
        ref = Database.database().reference().child("Restaurants")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for entry in snapshot.children {
                let snap = entry as! DataSnapshot
                let temp = restaurant(snap: snap, ID: snap.key)
                //let distanceInMeters : Double = self.userLocation.location!.distance(from: mapItems[row].placemark.location!)
                //let distanceInMiles : Double = ((distanceInMeters.description as String).doubleValue * 0.00062137)
                restaurants.append(temp)
            }
            self.listVC.delegateTable()
            self.mapVC.makeAnnotations()
            self.mapVC.flag = 1
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
        for i in 0..<restaurants.count{
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(restaurants[i].address!) { (placemarks, error) -> Void in
                if((error) != nil){
                    print("Error", error ?? "")
                }
                if let placemark = placemarks?.first {
                    let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                    let annotation = restaurantAnnotation(title: restaurants[i].restrauntName!, coordinate: coordinates, rID: restaurants[i].restrauntID!)
                    self.mapView.addAnnotation(annotation)
                }
            }
            
            
            
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.insetView.layer.cornerRadius = 5
        self.insetView.clipsToBounds = true
    }

}


