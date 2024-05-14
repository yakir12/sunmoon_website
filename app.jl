module App
using TOML
using GenieFramework
import DataFrames: DataFrame
import TimeZones: TimeZone
@genietools

using Main.SunMoonTables

dict = TOML.parsefile("Stations.toml")["stations"]
const STATIONS = Dict(v["name"] => v for v in values(dict))

function get_table(daterange::DateRange, station::String, crepuscular_elevation::Int, elevations_str::String)
    start_date = daterange.start
    end_date = daterange.stop
    dict = STATIONS[station]
    latitude = dict["latitude"]
    longitude = dict["longitude"]
    altitude = dict["altitude"]
    tz = TimeZone(dict["timezone"])
    elevations = parse.(Int, split(elevations_str, ','))
    df = SunMoonTables.get_table(start_date, end_date, latitude, longitude, altitude, tz, elevations, crepuscular_elevation)
    return DataTable(df)
end

# function magnetic_declination(start_date::Date, station::String)
#     latitude = dict["latitude"]
#     longitude = dict["longitude"]
#     altitude = dict["altitude"]
#     declination = SunMoon.magnetic_declination(decimaldate(start_date), latitude, longitude, altitude)
#     msg = "the magnetic declination angle is $(round(declination; digits=2))°"
#     return msg
# end

@app begin
    @in daterange = DateRange(now(), now()+Day(7))
    @out stations = collect(keys(STATIONS))
    @in station = first(keys(STATIONS))
    @in crepuscular_elevation = -20
    @in elevations_str = "20, 30, 45, 60, 75"
    @out data = get_table(DateRange(now(), now()+Day(7)), first(keys(STATIONS)), 0, "20, 30, 45, 60, 75")
    # @out declination_msg = magnetic_declination(Date(now()), first(keys(STATIONS)))

    @onchange daterange, station, crepuscular_elevation, elevations_str begin
        if all(x -> !isnothing(tryparse(Int, x)), split(elevations_str, ','))
            data = get_table(daterange, station, crepuscular_elevation, elevations_str)
            # declination_msg = magnetic_declination(daterange.start, station)
        end
    end
end

function ui()
    [
     item([
           itemsection(datepicker(:daterange, range=true, minimal=true)),
           itemsection(select(:station; options=:stations)),
           itemsection(slider(-90:0, :crepuscular_elevation, label = "", color = "teal")),
           itemsection(textfield("Elevations", :elevations_str, filled = "20, 30, 45, 60, 75"))
          ])
     # p(@text(:declination_msg))
     p(table(:data))
    ]
 end

 @page("/", ui)

end
