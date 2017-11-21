//
//  DealTableViewCell.swift
//  Savour
//
//  Created by Chris Patterson on 8/2/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

class DealTableViewCell: UITableViewCell {

    @IBOutlet weak var validHours: UILabel!
    @IBOutlet weak var insetView: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var tagImg: UIImageView!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rName: UILabel!
    @IBOutlet weak var Countdown: UILabel!
    @IBOutlet weak var dealDesc: UILabel!
    var deal: DealData!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.insetView.layer.cornerRadius = 10
        self.insetView.layer.shadowRadius = 2
        self.insetView.layer.shadowOpacity = 0.5
        self.insetView.layer.shadowOffset = CGSize(width: 6, height: 6)
        let maskPath = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 10.0, height: 10.0))
        
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        self.rImg.layer.mask = shape

        self.rImg.clipsToBounds = true

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    
    }
    
   
    @IBAction func likePressed(_ sender: Any) {
        if likeButton.title(for: .normal) != "Remove" {
            if favorites[deal.dealID!] == nil{
                favorites[deal.dealID!] = deal
                let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
                likeButton.setImage(image, for: .normal)
                likeButton.tintColor = UIColor.red
            }
            else{
                favorites.removeValue(forKey: deal.dealID!)
                let image = #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate)
                likeButton.setImage(image, for: .normal)
                likeButton.tintColor = UIColor.red
            }
        }
        
    }
}
