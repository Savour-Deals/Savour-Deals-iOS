//
//  DealTableViewCell.swift
//  Savour
//
//  Created by Chris Patterson on 8/2/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

class DealTableViewCell: UITableViewCell {

    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rName: UILabel!
    @IBOutlet weak var FavButton: UIButton!
    @IBOutlet weak var Countdown: UILabel!
    @IBOutlet weak var dealDesc: UILabel!
    var deal: DealData!
    override func awakeFromNib() {
        super.awakeFromNib()
        FavButton.layer.cornerRadius = 5
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
