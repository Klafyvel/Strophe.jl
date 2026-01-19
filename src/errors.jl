"Handle errors related to libstrophe."
struct StropheError <: Exception
    msg::String
end
