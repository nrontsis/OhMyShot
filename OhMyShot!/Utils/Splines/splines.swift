import Foundation

func smooth_spline_with_derivative(x: [Double], y: [Double], smoothing: Double) -> ([Double], [Double]) {
    if x.count < 3 { return (y, x.count == 2 ? [(y[1] - y[0])/(x[1] - x[0])] : []) }
    
    // Input arguments
    var inputs = x
    var outputs = y
    var relative_standard_deviations = [Double](repeating: 1.0, count: x.count)
    var error_variance: Double = 1.0
    var input_size = CInt(x.count)
    var include_error_estimates = CInt(0)
    var num_rows_in_spline_coefficient = CInt(input_size-1)
    
    // Output arguments
    var error_code = CInt(0)
    var spline_outputs = [Double](repeating: 1.0, count: x.count)
    var spline_coefficients = [Double](repeating: 1.0, count: 3*(x.count - 1))
    var bayesian_error_estimates = [Double](repeating: 1.0, count: x.count)
    var work_vector = [Double](repeating: 1.0, count: 7*(x.count + 2))
    
    cubgcv_with_manual_rho(&inputs, &outputs, &relative_standard_deviations, &input_size, &spline_outputs, &spline_coefficients, &num_rows_in_spline_coefficient, &error_variance, &include_error_estimates, &bayesian_error_estimates, &work_vector, &error_code, smoothing);
    
    let error_codes = [
        129: "ic is less than n-1",
        130: "n is less than 3",
        131: "input abscissae are not ordered so that x(i)<x(i+1)",
        132: "df(i) is not positive for some i",
        133: "job is not 0 or 1"
    ]
    precondition(
        error_code == 0,
        "Error \(error_code) in spline C call: \(error_codes[Int(error_code)] ?? "?")"
    )
    
    let spline_derivatives = spline_coefficients[0..<x.count-1]
    // let spline_second_derivatives = spline_coefficients[x.count-1..<2*(x.count-1)]
    // let spline_third_derivatives = spline_coefficients[Int(2*(x.count-1))...]

    return (spline_outputs, Array(spline_derivatives))
}
