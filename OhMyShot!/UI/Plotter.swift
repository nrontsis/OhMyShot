import AAInfographics
import CoreGraphics

import Foundation

func deltas(_ data: [Double], dt: Double = 0.1) -> [Double] {
    return stride(
        from: 0, to: data.count - 1, by: 1
    ).map{(data[$0 + 1] -  data[$0])/dt}
}


func create_past_shots_chart(width: CGFloat, height: CGFloat, show_rate: Bool) -> AAChartView {
    let unit = show_rate ? "g/s" : "g"
    var data = [[Double]]()
    for i in 0...3 {
        var series = load_shot_weight_per_decisecond(i)
        if is_true("plotsStartAtNonZeroWeight") {
            series = series.filter{$0 > setting("nonzeroWeightThreshold")}
        }
        data.append(show_rate ? moving_avergae(deltas(series), period: 25) : series)
    }
    var series = [AASeriesElement]()
    for (i, datum) in data.enumerated() {
        let name = i == 0 ? "Weight Last shot" : "Weight \(i) shot\(i > 1 ? "s" : "") before"
        series.append(AASeriesElement().name(name).data(datum.map{Double(round(100*$0)/100)}))
    }
    let aaChartView = AAChartView()
    aaChartView.frame = CGRect(x:0,y:0,width:width,height:height)
    let aaChartModel = AAChartModel()
    .chartType(.line)
    .animationType(.swingFromTo)
    .markerRadius(0)
    .tooltipValueSuffix(" " + unit)
    .categories((0...500).map { String(format: "%.1f", Double($0)/10.0) })
    .xAxisTickInterval(50)
    .colorsTheme(["#fe117c","#ffc069","#06caf4","#7dffc0"])
    .series(series)
    aaChartView.aa_drawChartWithChartModel(aaChartModel)
    return aaChartView
}
