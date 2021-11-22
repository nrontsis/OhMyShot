import Foundation

func interpolate(x_new: [Double], x: [Double], y: [Double]) -> [Double] {
    let lower_bound = min(x.min()!, x_new.min()!) - 1.0
    let upper_bound = max(x.max()!, x_new.max()!) + 1.0
    var extended_x = x
    extended_x.insert(lower_bound, at: 0)
    extended_x.append(upper_bound)
    var extended_y = y
    extended_y.insert(y.first!, at: 0)
    extended_y.append(y.last!)
    return interpolate_interior(x_new: x_new, x: extended_x, y: extended_y)
}


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

func moving_avergae(_ data: [Double], period: Int) -> [Double] {
    let result = (0..<data.count).compactMap { index -> Double in
        let range = index..<index + period
        let window = Array(data[range])
        return window.reduce(0.0, +)/Double(window.count)
    }
    return result
}

func median(_ array: [Double]) -> Double {
    let sorted = array.sorted()
    if sorted.count % 2 == 0 {
        return Double((sorted[(sorted.count / 2)] + sorted[(sorted.count / 2) - 1])) / 2
    } else {
        return Double(sorted[(sorted.count - 1) / 2])
    }
}
