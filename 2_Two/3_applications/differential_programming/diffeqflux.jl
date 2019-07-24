# taken from the Flux model zoo:
# https://github.com/FluxML/model-zoo/blob/da4156b4a9fb0d5907dcb6e21d0e78c72b6122e0/other/diffeq/ode.jl
using Pkg; Pkg.activate("../../..");
using Flux, DiffEqFlux, OrdinaryDiffEq, Plots

## Setup ODE to optimize
function lotka_volterra(du,u,p,t)
  x, y = u
  α, β, δ, γ = p
  du[1] = dx = α*x - β*x*y
  du[2] = dy = -δ*y + γ*x*y
end
u0 = [1.0,1.0]
tspan = (0.0,10.0)
p = [1.5,1.0,3.0,1.0]
prob = ODEProblem(lotka_volterra,u0,tspan,p)

# Verify ODE solution
sol = solve(prob,Tsit5())
plot(sol)

# Generate data from the ODE
sol = solve(prob,Tsit5(),saveat=0.1)
A = sol[1,:] # length 101 vector
t = 0:0.1:10.0
scatter!(t,A)

# Build a neural network that sets the cost as the difference from the
# generated data and 1

p = param([2.2, 1.0, 2.0, 0.4]) # Initial Parameter Vector
function predict_rd() # Our 1-layer neural network
  diffeq_rd(p,prob,Tsit5(),saveat=0.1)[1,:]
end
loss_rd() = sum(abs2,x-1 for x in predict_rd()) # loss function

# Optimize the parameters so the ODE's solution stays near 1

data = Iterators.repeated((), 100)
opt = ADAM(0.1)
cb = function () #callback function to observe training
  display(loss_rd())
  # using `remake` to re-create our `prob` with current parameters `p`
  display(plot(solve(remake(prob,p=Flux.data(p)),Tsit5(),saveat=0.1),ylim=(0,6)))
end
# Display the ODE with the initial parameter values.
cb()
Flux.train!(loss_rd, [p], data, opt, cb = cb)



# Embedding the ODE layer in a simple neural network
# is simple:
#
# m = Chain(
#   Dense(28^2, 32, relu),
#   # takes in the initial condition from the previous layer
#   x -> diffeq_rd(p,prob,Tsit5(),saveat=0.1,u0=x)),
#   Dense(32, 10),
#   softmax)
