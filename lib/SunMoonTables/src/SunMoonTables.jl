module SunMoonTables

using Dates
using AstroLib, DataFrames, TimeZones

export Crepuscular

function get_sun(jds, latitude, longitude, altitude)
    right_ascension, declination = sunpos(jds)
    altaz = eq2hor.(right_ascension, declination, jds, latitude, longitude, altitude)
end
get_sun_elevations(jds, latitude, longitude, altitude) = first.(get_sun(jds, latitude, longitude, altitude))

# decimaldate(dtm::Date) = year(dtm) + (dayofyear(dtm) - 1) / daysinyear(dtm)
# magnetic_declination(dt::Date, latitude, longitude, altitude) = magnetic_declination(decimaldate(dt), latitude, longitude, altitude)
# function magnetic_declination(year::Float64, latitude, longitude, altitude)
#     mfv = igrfd(year, altitude, latitude, longitude, Val(:geodetic))
#     return atand(mfv[2], mfv[1])
# end

function get_sun_azimuth(jd::Float64, latitude, longitude, altitude) 
    _, az, _ = get_sun(jd, latitude, longitude, altitude)
    az# + magnetic_declination()
end

totime(dt) = Dates.format(Time(dt), "HH:MM")

dt2julian(dt, tz) = TimeZones.zdt2julian(ZonedDateTime(dt, tz))

function fresh_df(desired_elevations)
    df = DataFrame(Date = String[])
    df[!, "↑crepuscular"] = String[]
    df[!, :Sunrise] = String[]
    for el in desired_elevations
        df[!, "↑$el"] = String[]
    end
    df[!, :Noon] = String[]
    for el in reverse(desired_elevations)
        df[!, "↓$el"] = String[]
    end
    df[!, :Sunset] = String[]
    df[!, "↓crepuscular"] = String[]
    return df
end

function one_day(dt, latitude, longitude, altitude, tz, desired_elevations)
    dts = range(DateTime(dt), step = Minute(1), length = 60*24 - 1)
    jds = dt2julian.(dts, tz)
    elevations = get_sun_elevations(jds, latitude, longitude, altitude)
    max_elevation, noon_i = findmax(elevations)
    min_elevation = minimum(elevations)
    noon = string(totime(dts[noon_i]), " ", round(Int, max_elevation), "°")
    up = map(desired_elevations) do el
        if min_elevation ≤ el ≤ max_elevation
            i = findnext(≥(el), elevations, 1)
            totime(dts[i])
        else
            "-"
        end
    end
    i = findnext(≥(0), elevations, 1)
    up[2] = string(up[2], " ", round(Int, get_sun_azimuth(jds[i], latitude, longitude, altitude)), "°")
    down = map(reverse(desired_elevations)) do el
        if min_elevation ≤ el ≤ max_elevation
            i = findnext(≤(el), elevations, noon_i + 1)
            totime(dts[i])
        else
            "-"
        end
    end
    i = findnext(≤(0), elevations, noon_i + 1)
    down[end - 1] = string(down[end - 1], " ", round(Int, get_sun_azimuth(jds[i], latitude, longitude, altitude)), "°")
    return (string(dt), up..., noon, down...)
end

# macro exported_enum(T, syms...)
#     return esc(quote
#                    @enum($T, $(syms...))
#                    export $T
#                    for inst in Symbol.(instances($T))
#                        eval($(Expr(:quote, :(export $(Expr(:$, :inst))))))
#                    end
#                end)
# end
# @exported_enum Crepuscular none=0 civil=-6 nautical=-12 astronomical=-18

@enum Crepuscular none=0 civil=-6 nautical=-12 astronomical=-18

function str2crepuscular(str)
    for instance in instances(Crepuscular)
        if str == string(instance)
            return instance
        end
    end
    return nautical
end

function get_table(start_date::Date, end_date::Date, latitude::Real, longitude::Real, altitude::Real, tz::TimeZone, desired_elevations, crepuscular_elevation::Crepuscular)
    unique!(desired_elevations)
    filter!(x -> 0 < x < 90, desired_elevations)
    sort!(desired_elevations)
    df = fresh_df(desired_elevations)
    pushfirst!(desired_elevations, Int(crepuscular_elevation), 0)
    for dt in start_date:end_date
        push!(df, one_day(dt, latitude, longitude, altitude, tz, desired_elevations))
    end
    if crepuscular_elevation == none
        select!(df, Not(r"crepuscular"))
    end
    return df
end

end
