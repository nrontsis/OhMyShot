import AAInfographics
import CoreGraphics
import Foundation

func create_past_shots_chart(parent_frame: CGRect, units: String) -> AAChartView {
    let aaChartView = AAChartView()
    aaChartView.frame = CGRect(x:0,y:0,width:parent_frame.width,height:parent_frame.height)
    let aaChartModel = AAChartModel()
    .chartType(.line)
    .animationType(.swingFromTo)
    .markerRadius(0)
    .tooltipValueSuffix(" " + units)
    .categories((0...500).map { String(format: "%.1f", Double($0)/10.0) })
    .xAxisTickInterval(50)
    .colorsTheme(["#fe117c","#ffc069","#06caf4","#7dffc0"])
    .series(get_past_shots_series(units: units))
    aaChartView.aa_drawChartWithChartModel(aaChartModel)
    aaChartView.scrollEnabled = false
    return aaChartView
}

func get_past_shots_series(units: String) -> [AASeriesElement] {
    var list_of_series = [AASeriesElement]()
    for i in 0..<number_of_shots_saved {
        var series = load_shot_weight_per_decisecond(i)
        let start_index = series.firstIndex{$0 >= setting("nonzeroWeightThreshold")} ?? 0
        series = units == "g/s" ? moving_average(deltas(series), period: 25) : series
        if is_true("plotsStartAtNonZeroWeight") {series = Array(series[start_index...])}
        let name = i == 0 ? "Weight Last shot" : "Weight \(i) shot\(i > 1 ? "s" : "") before"
        list_of_series.append(AASeriesElement().name(name).data(round_to(series, decimals: 2)))
    }
    return list_of_series
}
