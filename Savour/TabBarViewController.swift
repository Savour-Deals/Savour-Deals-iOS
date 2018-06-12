//
//  TabBarViewController.swift
//  Savour
//
//  Created by Chris Patterson on 11/10/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    var data: DealsData!
    var vendors: VendorsData!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    func dealSetup(completion: @escaping (Bool) -> Void){
        data = DealsData(completion: { (success) in
            self.vendors = VendorsData(completion: { (succ) in
                let firstTab = self.viewControllers![0] as! UINavigationController
                let firstView = firstTab.topViewController as! ViewController
                let secondTab = self.viewControllers![1] as! UINavigationController
                let secondView = secondTab.topViewController as! FavoritesViewController
                let thirdTab = self.viewControllers![2] as! UINavigationController
                let thirdView = thirdTab.topViewController as! VendorMapViewController
                
                firstView.dealsData = self.data
                secondView.dealsData = self.data
                thirdView.dealsData = self.data
                firstView.vendorsData = self.vendors
                secondView.vendorsData = self.vendors
                thirdView.vendorsData = self.vendors
                completion(true)
            })
        })
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool{
        let fromView: UIView = tabBarController.selectedViewController!.view
        let toView  : UIView = viewController.view
        if fromView == toView {
            return false
        }
        
        UIView.transition(from: fromView, to: toView, duration: 0.1, options: UIViewAnimationOptions.transitionCrossDissolve) { (finished:Bool) in
            
        }
        return true
    }
}
