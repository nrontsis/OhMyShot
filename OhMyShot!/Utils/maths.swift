import Foundation


func interpolate_interior(x_new: [Double], x: [Double], y: [Double]) -> [Double] {
    assert(x_new.first! >= x.first!, "non interior x_new")
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

func deltas(_ data: [Double], dt: Double = 0.1) -> [Double] {
    return stride(
        from: 0, to: data.count - 1, by: 1
    ).map{(data[$0 + 1] -  data[$0])/dt}
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

public func spline(x: [Double], y: [Double], smoothing: Double) -> [Double] {
    if x.count < 3 { return y }
    
    var _x = x
    var _f = y
    let n = x.count
    var df = [Double](repeating: 1.0, count: n)
    var _y = [Double](repeating: 1.0, count: n)
    var c = [Double](repeating: 1.0, count: 3*(n - 1))
    var se = [Double](repeating: 1.0, count: n)
    var wk = [Double](repeating: 1.0, count: 7*(n + 2))
    var _var: Double = 1.0
    var _n = CInt(n)
    var _job = CInt(0)
    var _ic = CInt(n - 1)
    var ier = CInt(0)
    cubgcv_with_manual_rho(&_x, &_f, &df, &_n, &_y, &c, &_ic, &_var, &_job, &se, &wk, &ier, smoothing);
    return _y
}
