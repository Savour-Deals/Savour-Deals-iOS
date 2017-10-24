//
//  RDealsTableViewCell.swift
//  Savour
//
//  Created by Chris Patterson on 8/11/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

class RDealsTableViewCell: UITableViewCell {

        @IBOutlet weak var FavButton: UIButton!
        @IBOutlet weak var Countdown: UILabel!
        @IBOutlet weak var dealDesc: UILabel!
        @IBOutlet weak var validHours: UILabel!
        @IBOutlet weak var insetView: UIView!
    
        var deal: DealData!
    
        override func awakeFromNib() {
            super.awakeFromNib()
            self.insetView.clipsToBounds = true
            self.insetView.layer.cornerRadius = 5
            self.insetView.layer.shadowRadius = 2
            self.insetView.layer.shadowOpacity = 0.5
            self.insetView.layer.shadowOffset = CGSize(width: 6, height: 6)
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            
            // Configure the view for the selected state
        }
        
        @IBAction func FavoriteToggled(_ sender: Any) {
            //If favorite star was hit, add or remove to favorites
            if favorites[deal.dealID!] == nil{
                favorites[deal.dealID!] = deal
                let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
                FavButton.setImage(image, for: .normal)
                FavButton.tintColor = UIColor.red
            }
            else{
                favorites.removeValue(forKey: deal.dealID!)
                let image = #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate)
                FavButton.setImage(image, for: .normal)
                FavButton.tintColor = UIColor.red
            }

        
    }

}
