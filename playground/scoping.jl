# Julia docs: https://docs.julialang.org/en/latest/manual/variables-and-scoping/

x = 42

function f()
    y = x + 3 # equivalent to `local y = x + 3`
    @show y
end

f()

y

# x is global whereas y is local (to the function f)

# we can create a global variables from a local scope
# but we must be explicit about it.
function g()
    global y = x + 3
    @show y
end

g()

y


# we ALWAYS need to be explicit when writing to globals from a local scope:
function h()
    x = x + 3
    @show x
end

h()

function h2()
    global x = x + 3
    @show x
end

h2()

# This fact can lead to subtle somewhat unintuitive errors:
a = 0
for i in 1:10
    a += 1
end



# Note that if we do not use global scope, everything is simple and intuitive:
function k()
    a = 0
    for i in 1:10
        a += 1
    end
    a
end

k()



# Variables are inherited from non-global scope
function nested()
    function inner()
        # Try with and without "local"
        j = 2
        k = j + 1
    end
    j = 0
    k = 0
    return inner(), j, k
end

nested()



function inner()
    j = 2 # Try with and without "local"
    k = j + 1
end

function nested()
    j = 0
    k = 0
    return inner(), j, k
end

nested()
