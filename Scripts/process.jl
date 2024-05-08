using CSV
using DataFrames
using PlotlyJS
using SmoothingSplines


df = DataFrame(CSV.File("data.csv"))
X_orig = df[!, "Time [s]"]#[68:end-57]#[1:4:end]
Y_orig = df[!, "weight [g]"]#[68:end-57]#[1:4:end]
Y = diff(Y_orig)./diff(X_orig)
X = X_orig[1:end-1]
spl = fit(SmoothingSpline, X, Y, 0.3)
Ypred = predict(spl) # fitted vector
plot(
    [
        scatter(x=X_orig, y=Y_orig, name="Original values"),
        scatter(x=X, y=cumsum(Ypred.*diff(X_orig)), name="Smoothed derivative"),
        scatter(x=X, y=Ypred, name="Smoothed derivative", yaxis="y2")
    ],
    Layout(
        title_text="Double Y Axis Example",
        xaxis_title_text="xaxis title",
        yaxis_title_text="yaxis title",
        yaxis2=attr(
            title="yaxis2 title",
            overlaying="y",
            side="right"
        )
    )
)
