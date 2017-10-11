//
//  DealTableViewCell.swift
//  Savour
//
//  Created by Chris Patterson on 8/2/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

class DealTableViewCell: UITableViewCell {

    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var tagImg: UIImageView!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rName: UILabel!
    @IBOutlet weak var Countdown: UILabel!
    @IBOutlet weak var dealDesc: UILabel!
    var deal: DealData!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    @IBAction func likePressed(_ sender: Any) {
        if likeButton.title(for: .normal) != "Remove" {
            if favorites[deal.dealID!] == nil{
                favorites[deal.dealID!] = deal
                likeButton.setImage(#imageLiteral(resourceName: "icons8-like_filled.png"), for: .normal)
                print("favorite")
            }
            else{
                print("unfavorite")
                favorites.removeValue(forKey: deal.dealID!)
                likeButton.setImage(#imageLiteral(resourceName: "icons8-like"), for: .normal)
            }
        }
        
    }
}
