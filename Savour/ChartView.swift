//
//  ChartView.swift
//  Savour
//
//  Created by Chris Patterson on 10/6/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Charts
import FirebaseDatabase
var minDate: Date!

class ChartView: UIViewController {
    var gradientLayer: CAGradientLayer!
    var ref: DatabaseReference!
    var deal: DealData!
    var dates = [Double]()
    var graphVals = [String:Double]()
    @IBOutlet weak var chart: LineChartView!
    @IBOutlet weak var delete: UIButton!
    @IBOutlet weak var edit: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        getRedeems()
    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func setupUI(){
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.title = deal.dealDescription
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1).cgColor,#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0.2548694349).cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        edit.layer.borderColor = UIColor.white.cgColor
        edit.layer.borderWidth = 1.0
        edit.layer.cornerRadius = 5
        delete.layer.borderColor = UIColor.white.cgColor
        delete.layer.borderWidth = 1.0
        delete.layer.cornerRadius = 5
        chart.chartDescription?.enabled = false
        chart.noDataText = "No Redemptions"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    func getRedeems(){
        ref = Database.database().reference().child("Redeemed").child(deal.dealID!)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            for entry in snapshot.children {
                let snap = entry as! DataSnapshot
                let temp = snap.value as! Double
                self.dates.append(temp)
            }
            if !self.dates.isEmpty{
                self.dates.sort()
                minDate = Date(timeIntervalSince1970: self.dates.min()! - 24*60*60)
                let maxDate = Date(timeIntervalSince1970: self.dates.max()! + 2*24*60*60)
                let cal = Calendar.current
                let diff = cal.dateComponents([.day], from: minDate, to: maxDate)
                let max = diff.day
                for i in 0..<max!{
                    self.graphVals["\(i)"] = 0
                }
                
                for date in self.dates{
                    let temp = Date(timeIntervalSince1970: date)
                    let cal = Calendar.current
                    let Components = cal.dateComponents([.day], from: minDate, to: temp)
                    self.graphVals["\(Components.day!)"] = self.graphVals["\(Components.day!)"]! + 1
                }
                self.updateGraph()
            }
        })
    }
    func updateGraph(){
        var lineChartEntry = [ChartDataEntry]()
        let formato:BarChartFormatter = BarChartFormatter()
        let xaxis:XAxis = XAxis()
        for i in 0..<graphVals.count{
            let _ = formato.stringForValue(Double(i), axis: xaxis)
            let value = ChartDataEntry(x: Double(i), y: graphVals["\(i)"]!)
            lineChartEntry.append(value)
        }
        xaxis.valueFormatter = formato
        let line = LineChartDataSet(values: lineChartEntry, label: "Times Redeemed")
        line.colors = [UIColor.white]
        line.mode = .horizontalBezier
        line.drawCirclesEnabled = false
        line.cubicIntensity = 0.05
        let data = LineChartData()
        data.addDataSet(line)
        data.setDrawValues(false)
        chart.xAxis.valueFormatter = xaxis.valueFormatter
        chart.xAxis.labelPosition = XAxis.LabelPosition.bottom
        chart.xAxis.granularity = 1
        chart.leftAxis.granularity = 1
        chart.leftAxis.axisMinimum = 0.0
        chart.rightAxis.enabled = false
        chart.data = data
    }
   
    @IBAction func deletePressed(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Promotion?", message: "Are you sure you want to delete this promotion? This will completely remove the promotion including all redemption information you are currently looking at.", preferredStyle: .alert)
      
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) -> Void in
            _ = Database.database().reference().child("Redeemed").child(self.deal.dealID!).removeValue()
            _ = Database.database().reference().child("Deals").child(self.deal.dealID!).removeValue()
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func editPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "editSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! DiscountViewController
        vc.deal = self.deal
    }
    
}

@objc(BarChartFormatter)
public class BarChartFormatter: NSObject, IAxisValueFormatter{
   
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        var xLabel: String!
         let temp = minDate.timeIntervalSince1970 + Double(24*60*60*value)
         let date = Date(timeIntervalSince1970: temp)
         let cal = Calendar.current
         let Components = cal.dateComponents([.month,.day], from: date)
         xLabel = "\(Components.month!)/\(Components.day!)"
        return xLabel
    }
}
