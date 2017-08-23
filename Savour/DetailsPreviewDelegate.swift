//
//  DetailsPreviewDelegate.swift
//  Savour
//
//  Created by Chris Patterson on 8/22/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

//TODO: Get forcetouch working!

extension DetailsViewController: 	UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = DealsTable.indexPathForRow(at: location),
            let cell = DealsTable.cellForRow(at: indexPath) as? DealTableViewCell else {
                return nil }
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = Deals[indexPath.row]
        VC.fromDetails = true
        VC.newImg = cell.rImg.image
        VC.preferredContentSize =
            CGSize(width: 0.0, height: 600)
        
        previewingContext.sourceRect = cell.frame
        
        return VC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
    }
    
    
}
