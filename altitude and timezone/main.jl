using Dates, Downloads
using Interpolations, TimeZoneFinder, DataDeps, NCDatasets

const ALTITUDE = Ref{Interpolations.GriddedInterpolation{Float64, 2, Matrix{Union{Missing, Int16}}, Gridded{Linear{Throw{OnGrid}}}, Tuple{Vector{Float64}, Vector{Float64}}}}()

function fallback_download(remotepath, localdir)
    @assert(isdir(localdir))
    filename = basename(remotepath)  # only works for URLs with filename as last part of name
    localpath = joinpath(localdir, filename)
    downloader = Downloads.Downloader()
    downloader.easy_hook = (easy, info) -> Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_LOW_SPEED_TIME, 60)
    Downloads.download(remotepath, localpath; downloader=downloader)
    return localpath
end

register(
         DataDep(
                 "Earth2014",
                 """
                 Reference:
                 - Hirt, C. and M. Rexer (2015), Earth2014: 1 arc-min shape, topography, bedrock 
                 and ice-sheet models — available as gridded data and degree-10,800 spherical 
                 harmonics, International Journal of Applied Earth Observation and Geoinformation
                 39, 103–112, doi:10.10.1016/j.jag.2015.03.001.
                 """,
                 "http://ddfe.curtin.edu.au/models/Earth2014/data_1min/GMT/Earth2014.BED2014.1min.geod.grd",
                 "c7350f22ccfdc07bc2c751015312eb3d5a97d9e75b1259efff63ee0e6e8d17a5",
                 fetch_method = fallback_download
                )
        )
ALTITUDE[] = NCDataset(datadep"Earth2014/Earth2014.BED2014.1min.geod.grd") do ds
    interpolate((ds["x"][:], ds["y"][:]), ds["z"][:, :], Gridded(Linear()))
end

get_altitude(latitude, longitude) = ALTITUDE[](longitude, latitude)


latitude = 55.71331
longitude = 13.20764

altitude = get_altitude(latitude, longitude)
tz = timezone_at(latitude, longitude)
