
region_counties <- function(.region){
  if (.region=='Midlands'){
    counties <-c( "Halton","Warrington","Blackburn with Darwen","North Lincolnshire",       
                  "Derby","Leicester","Rutland","Nottingham", 
                  "Herefordshire, County of","Telford and Wrekin","Stoke-on-Trent",
                  "Peterborough", "Milton Keynes","Cheshire East",
                  "Cheshire West and Chester", "Shropshire", "Bedford","Bolton","Bury", 
                  "Manchester" , "Oldham","Rochdale", "Salford", "Stockport", 
                  "Tameside","Trafford" ,"Wigan" , "Knowsley", "Liverpool", 
                  "St. Helens","Wirral" ,"Barnsley", "Doncaster","Rotherham",
                  "Sheffield","Birmingham", "Coventry","Dudley","Sandwell","Solihull",              
                  "Walsall","Wolverhampton","Kirklees", "Wakefield", "Cambridgeshire",
                  "Derbyshire", "Leicestershire", "Lincolnshire" , "Norfolk",
                  "Northamptonshire", "Nottinghamshire" , "Staffordshire", "Suffolk",
                  "Warwickshire", "Worcestershire", "Wrexham" )
  } else if (.region=='North'){
    counties <- c("Hartlepool","Middlesbrough", "Redcar and Cleveland", 
                  "Stockton-on-Tees","Darlington" , "East Riding of Yorkshire", "York", 
                  "County Durham","Northumberland","Newcastle upon Tyne",
                  "North Tyneside", "South Tyneside","Sunderland", "Bradford",
                  "Calderdale", "Leeds", "Gateshead","Cumbria","Lancashire", "North Yorkshire")
  } else if (.region=='SouthWest'){
    counties <- c("Bath and North East Somerset","Bristol, City of" ,"North Somerset",                     
                  "South Gloucestershire","Plymouth", "Torbay", "Swindon", "Portsmouth" , 
                  "Southampton", "Isle of Wight", "Cornwall", "Wiltshire",                          
                  "Bournemouth, Christchurch and Poole", "Dorset", "Devon",
                  "Gloucestershire", "Hampshire","Somerset")
  } else if (.region=='SouthEast') {
    counties <- c("Luton" ,"Southend-on-Sea","Thurrock", "Medway","Bracknell Forest"  ,    
                  "West Berkshire", "Reading","Slough" , "Windsor and Maidenhead", "Wokingham" ,            
                  "Brighton and Hove", "Central Bedfordshire", "City of London",
                  "Barking and Dagenham" ,"Barnet","Bexley", "Brent", "Bromley","Camden",
                  "Croydon","Ealing" , "Enfield","Greenwich", "Hackney", 
                  "Hammersmith and Fulham","Haringey", "Harrow","Islington", 
                  "Kensington and Chelsea", "Kingston upon Thames", "Lambeth", "Lewisham",              
                  "Merton", "Newham","Redbridge", "Richmond upon Thames", "Southwark",             
                  "Sutton" , "Tower Hamlets", "Waltham Forest","Wandsworth","Westminster",           
                  "Buckinghamshire", "East Sussex","Essex", "Hertfordshire", "Kent",                  
                  "Oxfordshire", "Surrey","West Sussex", "Hillingdon", "Hounslow", "Havering",
                  "Croydon", "Southwark", "Lambeth", "Brighton and Hove")
  } else if (.region=='Wales'){
    counties <- c("Isle of Anglesey","Gwynedd","Conwy","Denbighshire","Flintshire",
                  "Ceredigion","Pembrokeshire","Carmarthenshire","Swansea",
                  "Neath Port Talbot", "Bridgend","Vale of Glamorgan","Cardiff",
                  "Rhondda Cynon Taf", "Caerphilly","Blaenau Gwent","Torfaen",
                  "Monmouthshire","Newport","Powys", "Merthyr Tydfil")
  } else if (.region=='Cornwall') {
    counties <- c("Cornwall")
  } else {
    stop(sprintf('%s is not a valid region name pick from: c(Midlands, North, SouthWest, 
                 SouthEast, Wales, Cornwall)'))
  }
  return(counties)
}



generate_WLT_regions <- function(region, counties_gpkg) {
  
  counties_sf <- read_sf(counties_gpkg)
  
  counties <- region_counties(region)
  
  
  if (!dir.exists(file.path('int_files','WLT_regions'))) dir.create(file.path('int_files','WLT_regions'))
  
  gen_regions <- function(c_list, r_name){
    out_p <- file.path('int_files','WLT_regions', sprintf('%s_REGION.gpkg', r_name))
    create_buff_regions <- counties_sf %>%
      filter(ctyua19nm %in% c_list)%>%
      st_union() %>%
      st_buffer(5000) %>%
      st_as_sf() %>%
      mutate(val=1)
    write_sf(create_buff_regions,
             dsn=out_p)
    return(out_p)
  }
  
  
  gpkg_path <- gen_regions(counties, region)
  
  return(gpkg_path)
  
}

