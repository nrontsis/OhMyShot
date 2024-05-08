import AAInfographics
import CoreGraphics
import Foundation

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
