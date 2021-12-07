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
        let weight = load_shot_weight_per_decisecond(i)
        let time = (0..<weight.count).map{Double($0)/10.0}
        let (smoothed_data, smoothed_derivative) : ([Double], [Double]) = smooth_spline_with_derivative(x: time, y: weight, smoothing: 400)
        var series = units == "g/s" ? smoothed_derivative : Array(smoothed_data.suffix(smoothed_derivative.count))
        let start_index = weight.firstIndex{$0 >= setting("nonzeroWeightThreshold")} ?? 0
        var shot_duration: Double
        if let flow_stopped_idx = smoothed_derivative.suffix(70).firstIndex(where: {$0 <= 0.3}) {
            series = Array(series[..<min(flow_stopped_idx + 20, series.count)])
            shot_duration = Double(flow_stopped_idx) / 10.0
        }
        else {
            shot_duration = Double(series.count) / 10.0
        }
        let name = String(
            format:"#%d: %.1fg %.1f+%.1fs", i, series.max() ?? 0.0, Double(start_index)/10.0, shot_duration - Double(start_index)/10.0
        )
        list_of_series.append(AASeriesElement().name(name).data(
            round_to(is_true("plotsStartAtNonZeroWeight") ? Array(series[start_index...]) : series, decimals: 2))
        )
    }
    return list_of_series
}
