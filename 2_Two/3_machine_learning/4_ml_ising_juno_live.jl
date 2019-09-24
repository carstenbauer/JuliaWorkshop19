#---
# Download Ising Monte Carlo data from http://carstenbauer.eu/Ising.h5
#---
using Pkg; Pkg.activate("../..");

using Flux
using Flux: crossentropy, onecold, onehotbatch, params, throttle, @epochs
using HDF5, Plots
using Printf, Statistics, Random
using Base.Iterators: repeated

# exact critical temperature
const IsingTc = 1/(1/2*log(1+sqrt(2)))
const Ts = [0.1, 0.644, 1.189, 1.733, 2.069, 2.269, 2.278, 2.469, 2.822, 3.367, 3.911, 4.456, 5.0]

# load configurations
function loadconfs(filename, L, T)
    t = round(T, digits=3)
    h5open(filename, "r") do f
        c = read(f["L$L/T$t/confs"])
        cs = Float64.(reshape(c, (L^2,:)))
        cs = hcat(cs, -one(eltype(cs)) .* cs) # Z2 (spin flip) symmetry
        return cs
    end
end

L = 8
Tleft = 1.189 #1.189
Tright = 3.367 #3.367

confs_left = loadconfs("Ising.h5", L, Tleft)
confs_right = loadconfs("Ising.h5", L, Tright)

# visualize configurations
printconfs(confs) = plot([heatmap(Gray.(reshape(confs[:,i], (L,L))), ticks=false) for i in 1:100:size(confs, 2)]...)
printconfs(confs_left)
printconfs(confs_right)

# set up as training data
neach = size(confs_left, 2)
X = hcat(confs_left, confs_right)
labels = vcat(fill(1, neach), fill(0, neach))
Y = onehotbatch(labels, 0:1)
dataset = repeated((X, Y), 10)

# create neural network with 10 hidden units and 2 output neurons
Random.seed!(123)
m = Chain(
  Dense(L^2, 10, relu),
  Dense(10, 2),
  softmax)

# classify phases at all intermediate temperatures
function confidence_plot()
  results = Dict{Float64, Vector{Float32}}()
  for T in Ts
      confs = loadconfs("Ising.h5", L, T);
      results[T] = vec(mean(m(confs), dims=2).data)
  end
  results = sort(results)

  p = plot(keys(results) |> collect, reduce(hcat, values(results))',
      marker=:circle,
      xlab="temperature",
      ylabel="CNN confidence",
      labels=["paramagnet", "ferromagnet"])
  plot!(p, [IsingTc, IsingTc], [0, 1], ls=:dash, color=:black, label="IsingTc")
  display(p)
end

confidence_plot()

# define cost-function
loss(x, y) = crossentropy(m(x), y)
accuracy(x, y) = mean(onecold(m(x)) .== onecold(y))


evalcb = () -> begin
    @show(loss(X, Y))
    @show(accuracy(X, Y))
    confidence_plot()
end
opt = ADAM()

println("-------- Training")
@epochs 100 Flux.train!(loss, params(m), dataset, opt, cb = throttle(evalcb, 10))
