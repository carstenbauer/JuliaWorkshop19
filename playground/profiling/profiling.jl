function myfunction(n)
    for i = 1:n
        A = randn(100,100,20)
        m = maximum(A)
        Am = mapslices(sum, A; dims=2)
        B = A[:,:,5]
        Bsort = mapslices(sort, B; dims=1)
        b = rand(100)
        C = B.*b
    end
end

myfunction(1)

@profiler myfunction(10)

# Short for:
# Profile.clear()
# @profile myfunction(10)
# Juno.profiler()
