# Load Required Packages
required_packages <- c("sf", "R.utils", "scales", "deckgl", "htmlwidgets", "leaflet")

# Install Missing Packages
installed <- required_packages %in% rownames(installed.packages())
if (any(!installed)) {
    install.packages(required_packages[!installed])
}

# Load Libraries
invisible(lapply(required_packages, library, character.only = TRUE))

# Set Kontur Population Data URL for Japan
options(timeout = 300)  # Set download timeout
url <- "https://geodata-eu-central-1-kontur-public.s3.amazonaws.com/kontur_datasets/kontur_population_JP_20231101.gpkg.gz"
filename <- basename(url)  # Extract filename from URL

# Download and Unzip the Population Data
download.file(url = url, destfile = filename, mode = "wb")
R.utils::gunzip(filename, remove = FALSE)

# Load the Population Data Using `sf`
pop_data <- sf::st_read(dsn = sub(".gz$", "", filename)) %>%
    sf::st_transform(crs = "EPSG:4326")  # Transform CRS to EPSG:4326

# Define Color Palette Based on Population
palette <- scales::col_quantile(
    "viridis",        # Use 'viridis' color palette
    pop_data$population,  # Apply palette to the population data
    n = 6             # Number of color bins
)

# Assign Colors to Population Data
pop_data$color <- palette(pop_data$population)

# Define Properties for Interactive 3D Map
properties <- list(
    stroked = TRUE,               # Enable borders for polygons
    filled = TRUE,                # Enable filling polygons
    extruded = TRUE,              # Enable 3D extrusion based on population
    wireframe = FALSE,            # Disable wireframe
    elevationScale = 1,           # Set elevation scale
    getFillColor = ~color,        # Assign fill color based on population data
    getLineColor = ~color,        # Assign line color
    getElevation = ~population,   # Elevation corresponds to population
    getPolygon = deckgl::JS("d => d.geom.coordinates"),  # Get coordinates for polygons
    tooltip = "Population: {{population}}",  # Tooltip format
    opacity = 0.25                # Set transparency of polygons
)

# Create Interactive 3D Map Centered on Japan
map <- deckgl::deckgl(
    latitude = 36.2048,          # Latitude of Japan
    longitude = 138.2529,        # Longitude of Japan
    zoom = 5,                    # Initial zoom level
    pitch = 45                   # Set tilt/pitch angle for 3D view
) %>%
    deckgl::add_polygon_layer(data = pop_data, properties = properties) %>%
    deckgl::add_basemap(deckgl::use_carto_style())  # Add basemap for better context

# Export the Interactive Map as HTML
htmlwidgets::saveWidget(
    map, 
    file = "3D-Population-Map-Of-Japan.html", 
    selfcontained = FALSE  # Save HTML with external dependencies
)
