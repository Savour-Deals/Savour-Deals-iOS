//
//  DealTableViewCell.swift
//  Savour
//
//  Created by Chris Patterson on 8/2/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import FirebaseStorage

class DealTableViewCell: UITableViewCell {

    @IBOutlet weak var tempImg: UIImageView!
    @IBOutlet weak var validHours: UILabel!
    @IBOutlet weak var insetView: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var tagImg: UIImageView!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rName: UILabel!
    @IBOutlet weak var Countdown: UILabel!
    @IBOutlet weak var dealDesc: UILabel!
    @IBOutlet weak var countdownView: UIView!
    @IBOutlet weak var validDaysIndicator: UILabel!
    var deal: DealData!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.insetView.layer.cornerRadius = 10
        self.insetView.layer.shadowRadius = 2
        self.insetView.layer.shadowOpacity = 0.5
        self.insetView.layer.shadowOffset = CGSize(width: 6, height: 6)
        self.insetView.layer.cornerRadius = 10
        self.rImg.clipsToBounds = true
        self.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupUI(){
        if !self.deal.favorited!{
            let image = #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate)
            self.likeButton.setImage(image, for: .normal)
            self.likeButton.tintColor = UIColor.red
        }
        else{
            let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
            self.likeButton.setImage(image, for: .normal)
            self.likeButton.tintColor = UIColor.red
        }
        self.rName.text = deal.name! + " - " + String(format:"%.1f", deal.distanceMiles!) + " miles"
        self.dealDesc.text = deal.dealDescription
        self.validHours.text = deal.activeHours
        if deal.redeemed! {
            self.Countdown.text = "Deal Already Redeemed!"
            self.Countdown.textColor = UIColor.white
            self.validHours.text = ""
            self.countdownView.isHidden = false
        }
        else if self.deal.daysLeft! < 8{
            self.countdownView.isHidden = false
            self.Countdown.text = deal.countdown
        }else{
            self.countdownView.isHidden = true
        }
        self.tagImg.image = self.tagImg.image!.withRenderingMode(.alwaysTemplate)
        self.tagImg.tintColor = self.Countdown.textColor
        if let viewWithTag = rImg.viewWithTag(300){
            viewWithTag.removeFromSuperview()
        }
        if !self.deal.active{
            let view = UIView(frame: CGRect(x: rImg.frame.origin.x, y: rImg.frame.origin.y, width: rImg.frame.width, height: rImg.frame.height))
            view.backgroundColor = UIColor.gray.withAlphaComponent(0.9)
            view.tag = 300
            let label = UILabel(frame: CGRect(x: rImg.frame.origin.x, y: rImg.frame.origin.y, width: rImg.frame.width-40, height: rImg.frame.height))
            label.textAlignment = NSTextAlignment.center
            label.numberOfLines = 0
            label.center = view.center
            label.baselineAdjustment = .alignCenters
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.text = "Deal is currently unavailable. This deal is valid " + deal.inactiveString! + "."
            label.textColor = UIColor.white
            view.addSubview(label)
            rImg.addSubview(view)
        }
        var dots = ""
        for day in self.deal.activeDays{
            if day{
                dots = dots + "• "
            }else{
                dots = dots + "◦ "
            }
        }
        let attributedDots = NSMutableAttributedString(
            string: dots,
            attributes: [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue) : UIFont.systemFont(ofSize: 33.0)])
        let attributedDays = NSMutableAttributedString(
            string: "Su. Mo. Tu. We. Th. Fr. Sa.\n",
            attributes: [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue) : UIFont.systemFont(ofSize: 11.0)])
        attributedDays.append(attributedDots)
        if let label = self.validDaysIndicator{
            label.attributedText = attributedDays
            label.setLineSpacing(lineHeightMultiple: 0.8)
            label.textColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        }
        
    }
    
   
    @IBAction func likePressed(_ sender: Any) {
        if deal.favorited!{
            deal.favorited = false
            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("favorites").child(deal.id!).removeValue()
            let image = #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate)
            likeButton.setImage(image, for: .normal)
            likeButton.tintColor = UIColor.red
        }
        else{
            deal.favorited = true
            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("favorites").child(deal.id!).setValue(deal.id!)
            let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
            likeButton.setImage(image, for: .normal)
            likeButton.tintColor = UIColor.red
        }
    }
}

extension UILabel {
    
    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {
        
        guard let labelText = self.text else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        
        let attributedString:NSMutableAttributedString
        if let labelattributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelattributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        
        // Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
}
