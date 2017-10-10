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
        var deal: DealData!
    
        override func awakeFromNib() {
            super.awakeFromNib()
            FavButton.layer.cornerRadius = 5
            FavButton.layer.borderWidth = 1
            FavButton.layer.borderColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)

    }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            
            // Configure the view for the selected state
        }
        
        @IBAction func FavoriteToggled(_ sender: Any) {
            //If favorite star was hit, add or remove to favorites
            if (FavButton.titleLabel?.text == "Favorite" ){
                //Add deal to favorites and change text
                FavButton.setTitle("Unfavorite", for: .normal )
                favorites[deal.dealID!] = deal

            }
            else {
                //take deal out of favorites
                FavButton.setTitle("Favorite", for: .normal )
                favorites.removeValue(forKey: deal.dealID!)

            }

        
    }

}
