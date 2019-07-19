# Our colleague's project depends on a useless package
# (https://github.com/crstnbr/Useless.jl)
using Useless

life_universe_everything(question) = 42

println(life_universe_everything("What is the meaning of life?"))

# Step 1: instantiate the environment
# Step 2: run the code: julia --project=. code.jl