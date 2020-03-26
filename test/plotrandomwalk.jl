@time using GR
@time y=cumsum(randn(100_000))
@time p=plot(y)
@time display(p)

