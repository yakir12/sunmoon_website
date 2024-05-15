module App
using TOML
using GenieFramework
import DataFrames: DataFrame
import TimeZones: TimeZone
@genietools

using Main.SunMoonTables

dict = TOML.parsefile("Stations.toml")["stations"]
const STATIONS = Dict(v["name"] => v for v in values(dict))

function get_table(daterange::DateRange, station::String, crepuscular_str::String, elevations_str::String)
    start_date = daterange.start
    end_date = daterange.stop
    dict = STATIONS[station]
    latitude = dict["latitude"]
    longitude = dict["longitude"]
    altitude = dict["altitude"]
    tz = TimeZone(dict["timezone"])
    elevations = parse.(Int, split(elevations_str, ','))
    crepuscular_elevation = SunMoonTables.str2crepuscular(crepuscular_str)
    df = SunMoonTables.get_table(start_date, end_date, latitude, longitude, altitude, tz, elevations, crepuscular_elevation)
    return DataTable(df)
end

# function magnetic_declination(start_date::Date, station::String)
#     latitude = dict["latitude"]
#     longitude = dict["longitude"]
#     altitude = dict["altitude"]
#     declination = SunMoonTables.magnetic_declination(decimaldate(start_date), latitude, longitude, altitude)
#     msg = "the magnetic declination angle is $(round(declination; digits=2))°"
#     return msg
# end

@app begin
    @in daterange = DateRange(now(), now()+Day(7))
    @out stations = collect(keys(STATIONS))
    @in station = first(keys(STATIONS))
    @in crepuscular_str = "nautical"
    @in elevations_str = "20, 30, 45, 60, 75"
    @out data = get_table(DateRange(now(), now()+Day(7)), first(keys(STATIONS)), "nautical", "20, 30, 45, 60, 75")
    # @out declination_msg = magnetic_declination(Date(now()), first(keys(STATIONS)))

    @onchange daterange, station, crepuscular_str, elevations_str begin
        if all(x -> !isnothing(tryparse(Int, x)), split(elevations_str, ','))
            data = get_table(daterange, station, crepuscular_str, elevations_str)
            # declination_msg = magnetic_declination(daterange.start, station)
        end
    end
end

function crepuscular2radio(crepuscular_instance)
    label = string(crepuscular_instance)
    name = titlecase(label)
    α = Int(crepuscular_instance)
    radio("$name $(α)°", :crepuscular_str, val = label)
end

function ui()
    [
     item([
           itemsection(datepicker(:daterange, range=true, minimal=true)),
           itemsection(select(:station; options=:stations)),
           itemsection([crepuscular2radio(crepuscular_instance) for crepuscular_instance in instances(Crepuscular)]),
           itemsection(textfield("Elevations", :elevations_str, filled = "20, 30, 45, 60, 75"))
          ])
     # p(@text(:declination_msg))
     p(table(:data))
    ]
 end

 @page("/", ui)

end
