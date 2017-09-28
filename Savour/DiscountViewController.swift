//
//  DiscountViewController.swift
//  Savour
//
//  Created by Chris Patterson on 9/27/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

class DiscountViewController: UIViewController {
    @IBOutlet weak var BOGOContainer: UIView!
    @IBOutlet weak var percentContainer: UIView!
    @IBOutlet weak var dollarContainer: UIView!
    @IBOutlet weak var segmentCont: UISegmentedControl!
    var BOGOvc: BogoController!
    var PercVC: PercentController!
    var DolVC: DollarController!
    var Dealtype: String!
    var dealPromo: String!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if segmentCont.selectedSegmentIndex == 0 {
            showBOGO()
        }
        else if segmentCont.selectedSegmentIndex == 1 {
            showPerc()
        }
        else if segmentCont.selectedSegmentIndex == 2 {
            showDollar()
        }
    }
    
    func showBOGO(){
        BOGOContainer.isHidden = false
        percentContainer.isHidden = true
        dollarContainer.isHidden = true
    }
    
    func showPerc(){
        BOGOContainer.isHidden = true
        percentContainer.isHidden = false
        dollarContainer.isHidden = true
    }
    
    func showDollar(){
        BOGOContainer.isHidden = true
        percentContainer.isHidden = true
        dollarContainer.isHidden = false
    }
    
    @IBAction func exitPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func nextPressed(_ sender: Any) {
        if segmentCont.selectedSegmentIndex == 0 {
            dealPromo = "Buy One Get One Free \(BOGOvc.promoText.text!)"
            print(dealPromo)
        }
        else if segmentCont.selectedSegmentIndex == 1 {
            dealPromo = "\(PercVC.pickerDataSource[PercVC.pickerView.selectedRow(inComponent: 0)]) \(PercVC.promoItem.text!)"
            print(dealPromo)
        }
        else if segmentCont.selectedSegmentIndex == 2 {
            dealPromo = "\(DolVC.pickerDataSource[PercVC.pickerView.selectedRow(inComponent: 0)]) \(DolVC.promoItem.text!)"
            print(dealPromo)
        }
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if segmentCont.selectedSegmentIndex == 0 {
            showBOGO()
        }
        else if segmentCont.selectedSegmentIndex == 1 {
            showPerc()
        }
        else if segmentCont.selectedSegmentIndex == 2 {
            showDollar()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "bogo"{
            BOGOvc = segue.destination as! BogoController
        }
        if segue.identifier == "perc"{
            PercVC = segue.destination as! PercentController
        }
        if segue.identifier == "doll"{
            DolVC = segue.destination as! DollarController
        }
    }
    
}
class BogoController: UIViewController {
  
    @IBOutlet weak var promoText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
class PercentController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var pickerView: UIPickerView!
    var pickerDataSource = [String]()
    
    @IBOutlet weak var promoItem: UITextField!
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        for dollars in 1...50 {
            pickerDataSource.append("$\(dollars) off")
        }
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
    }
  
}
class DollarController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var pickerView: UIPickerView!
    var pickerDataSource = [String]()
    
    @IBOutlet weak var promoItem: UITextField!
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for index in 1...12 {
            let percent = index * 5
            pickerDataSource.append("\(percent)% off")
        }
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
    }
    
}
