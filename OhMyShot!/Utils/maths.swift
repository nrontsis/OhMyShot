import Foundation


func interpolate_interior(x_new: [Double], x: [Double], y: [Double]) -> [Double] {
    assert(x_new.first! >= x.first!, "Interpolating index is not contained in the original index")
    assert(x_new.last! <= x.last!, "non interior x_new")
    var y_new = [Double]()
    var i = 0
    while y_new.count < x_new.count {
        if x_new[y_new.count] < x[i] {
            let slope = (y[i] - y[i - 1])/(x[i] - x[i - 1])
            let dt = x_new[y_new.count] - x[i - 1]
            y_new.append(y[i - 1] + dt * slope)
        }
        else {
            i += 1
        }
    }
    return y_new
}

func interpolate_interior(x: [Double], y: [Double], step: Double) -> [Double] {
    return interpolate_interior(
        x_new: Array(stride(from: x.min()!, to: x.max()!, by: step)),
        x: x,
        y: y
    )
}

func moving_average(_ data: [Double], period: Int) -> [Double] {
    let result = (0..<data.count).compactMap { index -> Double in
        let range = max(index - period + 1, 0)...index
        let window = Array(data[range])
        return window.reduce(0.0, +)/Double(window.count)
    }
    return result
}

func finite_differences(x: [Double], y: [Double]) -> [Double] {
    let diff_x = stride(from: 0, to: x.count - 1, by: 1).map{x[$0 + 1] - x[$0]}
    let diff_y = stride(from: 0, to: y.count - 1, by: 1).map{y[$0 + 1] - y[$0]}
    return zip(diff_x, diff_y).map{$1/$0}
}


func drop_delayed_measurements(_ s: TimeSeries, dt_threshold: Double) -> TimeSeries {
    let indices_to_keep = [0] + (1..<s.times.count).filter{s.times[$0] - s.times[$0 - 1] <= dt_threshold}
    return TimeSeries(
        times: indices_to_keep.map{s.times[$0]},
        values: indices_to_keep.map{s.values[$0]}
    )
}

func round_to(_ data: [Double], decimals: Int) -> [Double] {
    let scaling = pow(10, Double(decimals))
    return data.map{round(scaling*$0)/scaling}
}
