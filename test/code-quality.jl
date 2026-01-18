@testitem "Aqua.jl tests." tags = [:aqua, :codequality] begin
    using Aqua
    Aqua.test_all(Strophe)
end

@testitem "JET.jl tests." tags = [:jet, :codequality] begin
    using JET
    JET.test_package(Strophe)
end
