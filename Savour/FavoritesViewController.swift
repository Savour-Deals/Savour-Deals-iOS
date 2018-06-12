//
//  FavoritesViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/6/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import FirebaseStorageUI
import FirebaseAuth
import CoreLocation

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    var storage: Storage!
    @IBOutlet weak var heartImg: UIImageView!
    @IBOutlet weak var emptyView: UIView!
    var dealsData: DealsData!
    var vendorsData: VendorsData!
    var favDeals =  [DealData]()
    var user: String!
    @IBOutlet weak var FavTable: UITableView!
    var ref: DatabaseReference!
    var statusBar: UIView!
    var count = 0
    let placeholderImgs = ["Savour_Cup", "Savour_Fork", "Savour_Spoon"]
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: self.FavTable)
        } else {
            print("3D Touch Not Available")
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        setupUI()
    }
    
    func setupUI(){
        self.navigationController?.navigationItem.title = "Favorites"
        self.navigationController?.navigationBar.tintColor = UIColor(red: 73/255, green: 171/255, blue: 170/255, alpha: 1.0)
        heartImg.image = self.heartImg.image?.withRenderingMode(.alwaysTemplate)
        heartImg.tintColor = UIColor.red
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        let (activeFav,inactiveFav) = dealsData.getFavorites()
        self.favDeals.removeAll()
        for deal in activeFav{
            if !self.favDeals.contains(where: { $0.id == deal.id }){
                self.favDeals.append(deal)
            }
        }
        for deal in inactiveFav{
            if !self.favDeals.contains(where: { $0.id == deal.id }){
                self.favDeals.append(deal)
            }
        }
        self.FavTable.reloadData()
        FavTable.tableFooterView = UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (favDeals.isEmpty){
            emptyView.isHidden = false
        }else{
            emptyView.isHidden = true
        }
        return favDeals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        cell.deal = favDeals[indexPath.row]
        cell.tempImg.image = UIImage(named: placeholderImgs[count])
        count = count + 1
        if count > 2{
            count = 0
        }
        let photo = cell.deal?.photo!
        if photo != ""{
            // UIImageView in ViewController
            let imageView: UIImageView = cell.rImg
            cell.tempImg.image = UIImage(named: placeholderImgs[count])
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: URL(string:photo!), completed: { (img, err, typ, ref) in
                cell.tempImg.isHidden = true
            })
        }
        cell.likeButton.addTarget(self,action: #selector(removePressed(sender:event:)),for:UIControlEvents.touchUpInside)
        cell.setupUI()
        return cell
    }
    
    @IBAction func removePressed(sender: UIButton, event: UIEvent){
        let touches = event.touches(for: sender)
        if let touch = touches?.first{
            let point = touch.location(in: FavTable)
            if let indexPath = FavTable.indexPathForRow(at: point) {
                let cell = FavTable.cellForRow(at: indexPath) as? DealTableViewCell
                let user = Auth.auth().currentUser?.uid
                Database.database().reference().child("Users").child(user!).child("Favorites").child((cell?.deal.id!)!).removeValue()
                favDeals.remove(at: indexPath.item)
                self.FavTable.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = favDeals[indexPath.row]
        VC.dealsData = self.dealsData
        VC.fromDetails = false
        VC.photo = VC.Deal?.photo
        if let vendor = vendorsData.getVendorsByID(id: VC.Deal.rID!){
            VC.thisVendor = vendor
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.pushViewController(VC, animated: true)
        }else {
            let alert = UIAlertController(title: "Oops!", message: "Sorry! We could not get information about this deal at this time. We are working on this!", preferredStyle: .alert)
            let approveAction = UIAlertAction(title: "Okay", style: .default) { (alert: UIAlertAction!) -> Void in}
            alert.addAction(approveAction)
            self.present(alert, animated: true, completion:nil)
        }

    }

    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension FavoritesViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = FavTable.indexPathForRow(at: location),
            let cell = FavTable.cellForRow(at: indexPath) as? DealTableViewCell else {
                return nil }
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = favDeals[indexPath.row]
        VC.fromDetails = false
        VC.dealsData = self.dealsData
        if let vendor = vendorsData.getVendorsByID(id: VC.Deal.rID!){
            VC.thisVendor = vendor
        }else{
            let alert = UIAlertController(title: "Oops!", message: "Sorry! We could not get information about this deal at this time. We are working on this!", preferredStyle: .alert)
            let approveAction = UIAlertAction(title: "Okay", style: .default) { (alert: UIAlertAction!) -> Void in}
            alert.addAction(approveAction)
            self.present(alert, animated: true, completion:nil)
        }
        VC.photo = VC.Deal?.photo
        VC.preferredContentSize =
            CGSize(width: 0.0, height: 600)
        previewingContext.sourceRect = cell.frame
        return VC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
