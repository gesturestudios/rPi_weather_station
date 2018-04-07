# import libraries----------
library(shiny)
library(shinydashboard)
library(plotly)
library(ggplot2)
library(RMySQL)
library(dplyr)
library(reshape2)
library(gsheet)

hexcolor <- function(x){
  if (x>100) {result = "#9E0142"}
  else if (x>90) {result = "#9E0142"}
  else if (x>80) {result = "#D62F27"}
  else if (x>70) {result = "#F46C43"}
  else if (x>60) {result = "#FCAD60"}
  else if (x>50) {result = "#FDDF90"}
  else if (x>40) {result = "#DFF3F8"}
  else if (x>30) {result = "#ABD9E9"}
  else if (x>20) {result = "#4575B4"}
  else {result = "#303694"}
  return(result)
}

textcolor <- function(x){
  if (x>100) {result = "maroon"}
  else if (x>80) {result = "red"}
  else if (x>60) {result = "orange"}
  else if (x>50) {result = "yellow"}
  else if (x>40) {result = "aqua"}
  else if (x>30) {result = "light-blue"}
  else if (x>20) {result = "blue"}
  else {result = "navy"}
  return(result)
}

ui <- dashboardPage(#======================================================================
  dashboardHeader(title = textOutput("curdate"),titleWidth = 350),
  dashboardSidebar(#-----------------------------------------------------------------======
    sidebarMenu(
      menuItem("Overview",  tabName = "overview",  icon = icon("address-card")),
      menuItem("Power consumption",  tabName = "power",  icon = icon("bolt"),
                 menuSubItem("Daily",tabName = 'byDay'),
                 menuSubItem("Hourly",tabName = 'byHour')
      ),
      menuItem("Bills",   tabName = "bills",  icon = icon("dollar"),
                 menuSubItem("Utility bills",tabName = "utility"),
                 menuSubItem("Home improvement",tabName = "homeimp")
      ),
      menuItem("Current temperature",tabName = "temps",  icon = icon("thermometer")),
      menuItem("Current weather",    tabName = "weather",icon = icon("cloud")),
      menuItem("Darksky map",    tabName = "weathermap", icon = icon("map")),
      box(
        title="Slider for all graphs",background = "blue",width = 13,
        sliderInput(inputId = "days", 
                    label = "Choose number of days to plot", 
                    value = 5, min = 1, max = 30,ticks=FALSE)
      )
      
    )
  ),
  dashboardBody(#--------------------------------------------------------------------------
    tabItems(
      tabItem(tabName = "overview",#-------------------------------------------------------
              valueBoxOutput("outside"),
              valueBoxOutput("inside"),
              valueBoxOutput("climate_status"),
              tags$iframe(
                seamless = "seamless", 
                src = "https://forecast.io/embed/#lat=45.4813&lon=-122.8490&name=our backyard", 
                height = 250, width = 600
              ),
              box(
                background = "navy",width = "450px", height = "170px",
                img(src='moon-150x150.png'),
                img(src='daylight-300x150.png'),
                img(src="http://www.hamqsl.com/solar101vhfpic.php")
              )
              
              # tags$iframe(
              #   seamless = "seamless", 
              #   src = "moon-150x150.png", 
              #   height = 150, width = 150
              #   )
              #,
              #img(src='moon-210x210.png', align = 'top')
              ),
      tabItem(tabName = "byDay",#----------------------------------------------------------
              #h2("power consumption by day")
              plotlyOutput("PGEdailyplot",height = "300px")
              ),
      tabItem(tabName = "byHour",#---------------------------------------------------------
              #h2("power consumption by the hour"),
              plotlyOutput("PGEplot",height = "300px")
      ),
      tabItem(tabName = "utility",#----------------------------------------------------------
              box(
                title="Summary of bills",background = "light-blue",width = 3,
                uiOutput("choose_billers"),
                uiOutput("choose_years"),
                box(
                  title="Upcoming bills",background = "red",width = 2.75,
                  htmlOutput("upcoming_bills")
                ),
                box(
                  title="Recently paid",background = "green",width = 2.75,
                  htmlOutput("paid_bills")
                )
                
              ),
              box(
                title = "Plot of selected provider bills over selected year range",background = "navy",width = 9,
                plotlyOutput("billplot")
              )
      ),
      tabItem(tabName = "homeimp",#----------------------------------------------------------
              box(
                title="Choose years to summarize:",background = "light-blue",width = 3,
                uiOutput("hd_years")
              ),
              box(
                title = "Total spending at Home Depot over selected year range",background = "navy",width = 9,
                plotlyOutput("hdspendingplot")
              )
      ),
      tabItem(tabName = "temps",#----------------------------------------------------------
              box(
                title="Most recent temps",background = "light-blue",width = 4,
                plotlyOutput("INOUTplot")
              ),
              box(
                title="Temperatures over time- use slider to adjust range",background = "navy",width = 8,
                plotlyOutput("tempsplot",height = 600),
                plotlyOutput("furnaceplot", height = 100)
              )
      ),
      tabItem(tabName = "weather",#--------------------------------------------------------
              box(
                title="current conditions",background = "light-blue",width = 4
                
              ),
              box(
                title="recent observations",background = "navy",width = 8,
                plotlyOutput("simpletemp",height="200px"),
                plotlyOutput("simplehumid",height="200px"),
                plotlyOutput("simplebarometer",height="200px")
              )
      ),
      tabItem(tabName = "weathermap",#--------------------------------------------------------
              box(
                title="forecast map from Dark Sky",background = "light-blue",width = 4
                
              ),
              tabPanel("Map",
                       br(),
                       htmlOutput("darkmapframe")
              )
      )
    )
  )
)
# -----------------------------------------------------------------------------------------
server <- function(input, output) {#=======================================================
  # connect to data sources and retrieve data--------------------------------------------------
  # home server connection
  mydb = dbConnect(MySQL(), user='arduinouser', password='arduino', dbname='arduino_data', host='127.0.0.1')
  intemps <- dbGetQuery(mydb, "SELECT * FROM `INDOOR_TEMPS` WHERE `READ_TIME` >= now() - INTERVAL 30 DAY ORDER BY `READ_TIME` DESC;")
  outdat  <- dbGetQuery(mydb, "SELECT * FROM `PiStation` WHERE `READ_TIME` >= now() - INTERVAL 30 DAY ORDER BY `READ_TIME` DESC;")
  nestdat <- dbGetQuery(mydb, "SELECT * FROM `NEST_DATA` WHERE `datetime` >= now() - INTERVAL 30 DAY ORDER BY `datetime` DESC;")
  df      <- dbGetQuery(mydb, "SELECT * FROM `PGE_usage` WHERE `usage_date` > '2017-04-11';")
  
  intemps$stpt = as.POSIXct(strptime(intemps$READ_TIME, format="%Y-%m-%d %H:%M:%S"))
  outdat$stpt = as.POSIXct(strptime(outdat$READ_TIME, format="%Y-%m-%d %H:%M:%S"))
  nestdat$stpt = as.POSIXct(strptime(nestdat$datetime, format="%Y-%m-%d %H:%M:%S"))
  df$stpt = as.Date(df$usage_date, format="%Y-%m-%d")
  
  # utility bill data from Google Sheet
  bills = gsheet2tbl('https://docs.google.com/spreadsheets/d/1omTXqs6xDdzzUHfDOYOi5picPXoUVDkpcY7-IH9QDFA/edit?usp=sharing')
  bills$dateob = as.Date(bills$DUE_DATE,"%m/%d/%Y")
  nulldates = bills$DUE_DATE[is.na(bills$dateob)]
  bills$dateob[is.na(bills$dateob)] = as.Date(nulldates,"%b %d,%Y")
  bills$month = as.numeric(format(bills$dateob,'%m'))
  bills$year = as.numeric(format(bills$dateob,'%Y'))
  bills$month_abb = month.abb[bills$month]
  bills$month_abb <- factor(bills$month_abb,levels=month.abb)
  recent_bills = summarize(group_by(bills,SOURCE),
                           lastbills = max(dateob))
  recent_bills$status = recent_bills$lastbills - Sys.Date()
  upcoming = subset(recent_bills,lastbills>=Sys.Date())
  if (nrow(upcoming)>=1){
    upcoming$str = paste(upcoming$SOURCE," due in ",upcoming$status," days on ",format(upcoming$lastbills,"%b %d"))}
  paid = subset(recent_bills,lastbills<Sys.Date())
  if (nrow(paid)>=1){
    paid$str = paste(paid$SOURCE," last paid on ",format(paid$lastbills,"%b %d"))}
  
  # Home Depot spending from Google Sheet
  homedepotsheet = gsheet2tbl("https://docs.google.com/spreadsheets/d/1OB0TD1gkaYtPGSwrTMZzo_EsymR9cENYbgubf-RwBzU/edit?usp=sharing")
  hddf = data.frame(Datestr = as.Date(character()),
                  receipt_amount = numeric(),
                  stringsAsFactors = FALSE)
  for (i in 1:nrow(homedepotsheet)){
    test = sub(".*USD\\$ ","",homedepotsheet[i,4])
    hddf[i,2] = as.numeric(sub(" .*","",test))
    hddf[i,1] =as.Date(sub(" at .*","",homedepotsheet[i,1]),format = "%B %d, %Y")
  }
  hddf <- hddf[order(hddf$Datestr),]
  hddf$year = as.numeric(format(hddf$Datestr,'%Y'))
  hddf$CommonDate <- as.Date(paste0("2000-",format(hddf$Datestr, "%j")), "%Y-%j")
  hddf$cumsum <- do.call(c, tapply(hddf$receipt_amount, hddf$year, FUN=cumsum))
  
  # renders for header --------------------------------------------------------------------
  output$curdate <- renderText({format(Sys.time(), "%A %B %d, %I:%M %p")  })
  # renders for summary page---------------------------------------------------------------
  output$outside    <- renderValueBox({
    valueBox(
      icon("thermometer-4"),
      value=outdat$OUTSIDE_TEMP[1],
      subtitle="outside",
      color=textcolor(outdat$OUTSIDE_TEMP[1])
    )
  })
  output$inside    <- renderValueBox({
    valueBox(
      icon("thermometer-4"),
      value=nestdat$NEST_TEMP[1],
      subtitle="inside",
      color=textcolor(nestdat$NEST_TEMP[1])
    )
  })
  output$climate_status    <- renderValueBox({
    if (nestdat$NEST_MODE[1] == "eco"){
      mode_icon = "leaf"
      mode_color="green"}
    else if ((nestdat$NEST_MODE[1] == "heat")){
      mode_icon = "fire"
      mode_color="red"}
    else if ((nestdat$NEST_MODE[1] == "cool")){
      mode_icon = "snowflake-o"
      mode_color="light-blue"}
    else if ((nestdat$NEST_MODE[1] == "off")){
      mode_icon = "power-off"
      mode_color="purple"}
    else {
      mode_icon = "exclamation-sign"
      mode_color="orange"}
    valueBox(
      subtitle = "thermostat set to",
      value=nestdat$NEST_MODE[1],
      icon(mode_icon),
      color=mode_color
    )
  })
  
  # renders for hourly energy usage page --------------------------------------------------
  melted_frame = melt(df,id=c("stpt","usage_date"))
  melted_frame = melted_frame[order(melted_frame[,1],melted_frame[,3]),]
  melted_frame$hr = as.integer(substr(melted_frame$variable,2,3))
  hourly_means = summarize(group_by(melted_frame,hr),
                           av_kwh = mean(value),
                           sd_kwh = sd(value))

  output$PGEplot <- renderPlotly({
    recent_means = summarize(group_by(subset(melted_frame,stpt>=(Sys.Date()-(input$days))),hr),
                             av_kwh = mean(value),
                             sd_kwh = sd(value))
    p = ggplot()+ 
      geom_bar(data=hourly_means, aes(y=av_kwh,x=hr),stat="identity")+
      geom_point(data = subset(melted_frame,stpt>=(Sys.Date()-(input$days))), 
                 aes(x = hr, y = value, color=value,text = paste("date",usage_date)),show.legend=FALSE)+ 
      scale_colour_gradientn(colours = topo.colors(10))+
      geom_line(data=recent_means, aes(y=av_kwh,x=hr),color="orange")+
      labs(x="hour (24 hour cycle)",y="kWh used")+
      theme_dark()
    p})
  
  # renders for daily energy usage page ---------------------------------------------------
  df$tot_kWh = rowSums(df[,2:25])
  mean_daily_kwh = mean(df$tot_kWh)
  df$meankwh = mean_daily_kwh
  
  output$PGEdailyplot <- renderPlotly({
    pge = subset(df,stpt>=(Sys.Date()-(input$days)),select = c(stpt,tot_kWh,meankwh))

    pg = ggplot(data=pge)+ 
      #geom_bar(aes(y=tot_kWh,x=stpt),stat="identity")+
      geom_area(aes(y=tot_kWh,x=stpt),color="orange")+
      #scale_colour_gradientn(colours = topo.colors(10))+
      geom_line(aes(y=meankwh,x=stpt),color="white")+
      labs(x="day",y="kWh used")+
      theme_dark()
    pg})
  # renders for utility page -------------------------------------------------------------
  output$choose_billers <- renderUI({
    billers = unique(bills$SOURCE)
    checkboxGroupInput(inputId = "billervariable",label = "Choose bills to display",
                       choices = billers,selected = billers)
  })
  output$choose_years <- renderUI({
    yearoptions = unique(bills$year)
    checkboxGroupInput(inputId = "yearvariable",label = "Choose years to display",
                       choices = yearoptions,selected = yearoptions)
  })
  output$upcoming_bills <- renderUI({HTML(paste0(upcoming$str,sep='<br/>'))})
  output$paid_bills <- renderUI({HTML(paste0(as.list(paid$str),sep='<br/>'))})
  output$billplot <- renderPlotly({
    bills2plot = subset(bills, SOURCE %in% input$billervariable & year %in% input$yearvariable,
                        c(SOURCE,year,month_abb,DUE,dateob))
    bills2plot$SOURCE <- factor(bills2plot$SOURCE)
    bills2plot$year <- factor((bills2plot$year))
    
    bills2plot.all <- rbind(bills2plot, cbind(expand.grid(
      SOURCE=levels(bills2plot$SOURCE), 
      month_abb=levels(bills2plot$month_abb),
      year = levels(bills2plot$year)), DUE=NA, dateob=NA))
    
    billplot = ggplot(bills2plot.all,aes(SOURCE,DUE))+
      geom_bar(aes(fill=SOURCE,text=dateob),position="dodge",stat="identity")+
      theme(axis.text.x=element_blank(),axis.title.x=element_blank(),axis.ticks.x=element_blank())+
      facet_grid(year~month_abb)+labs(y="Bill amount ($)", fill="Provider")
      
    billplot})
  
  # renders for home depot page---------------------------------------------------------
  output$hd_years <- renderUI({
    hdyearoptions = unique(hddf$year)
    checkboxGroupInput(inputId = "hdyear",label = "Choose years to display",
                       choices = hdyearoptions,selected = hdyearoptions)
  })
  output$hdspendingplot <- renderPlotly({
    hdplotdata = subset(hddf, year %in% input$hdyear)
    hdplot = ggplot(hdplotdata,aes(x=CommonDate,y=cumsum)) + 
      geom_area(fill='red',alpha=0.5) + 
      geom_point(aes(size=receipt_amount,text=Datestr)) +
      facet_grid(year~.)+
      labs(y="Total spending ($)",x="")+
      scale_x_date(labels = function(x) format(x, "%d-%b")) +    
      theme(legend.position = "none")
    hdplot})
  # renders for temperature page ----------------------------------------------------------
  curtemps = intemps[1,c(1:3)]
  curtemps$PiStation = outdat$OUTSIDE_TEMP[1]
  curtemps$Nest = nestdat$NEST_TEMP[1]
  curtemps$loc = "Inside"
  temps = melt(curtemps,id="loc")
  temps$loc[temps$variable=="PiStation"] = "Outside"
  temps$fillcolors = lapply(temps$value,hexcolor)

  tbars <- ggplot()+
    geom_bar(data=temps,aes(fill=variable,x=variable,y=value),position="dodge",stat="identity",show.legend=FALSE)+
    facet_wrap(~loc, scales = "free_x",shrink = TRUE)+
    scale_y_discrete(name="Temperature (F)")+
    theme_dark()+  
    scale_fill_manual(values=temps$fillcolors)+
    theme(axis.title.x=element_blank(),axis.text.x=element_blank(),axis.ticks.x=element_blank(),legend.position="none")
  output$INOUTplot <- renderPlotly({
    tbars})
  
  intemps_2_melt = intemps[,c(1,2,3,5)]
  melted_intemps = melt(intemps_2_melt,id=c("stpt"))
  nestdat_2_melt = nestdat[,c(2,12)]
  melted_nest    = melt(nestdat_2_melt,id=c("stpt"))
  outdat_2_melt  = outdat[,c(1,5)]
  melted_outdat  = melt(outdat_2_melt,id=c("stpt"))
  tempplot_data = rbind(melted_intemps,melted_nest,melted_outdat)
  # render plot:
  output$tempsplot <- renderPlotly({
    tempplot = ggplot(data = subset(tempplot_data,stpt>=(Sys.time()-(input$days*24*60*60))))+
      geom_line(aes(x=stpt,y=value,color=variable,text=stpt))+
      theme_dark()+
      theme(axis.title.x=element_blank(),axis.title.y=element_blank(),legend.position="none")
  })
  output$furnaceplot = renderPlotly({
    nestsubset = subset(nestdat,stpt>=(Sys.time()-(input$days*24*60*60)))
    for (i in 1:nrow(nestsubset)) {
      if(nestsubset$NEST_AWAY[i] =="home") {nestsubset$HOME[i] = 1} else {nestsubset$HOME[i] = 0}
      if(nestsubset$NEST_MODE[i] =="heat") {nestsubset$HEAT[i] = 1} else {nestsubset$HEAT[i] = 0}
      if(nestsubset$NEST_MODE[i] =="eco") {nestsubset$ECO[i] = 1} else {nestsubset$ECO[i] = 0}
      if(nestsubset$NEST_MODE[i] =="cool") {nestsubset$COOL[i] = 1} else {nestsubset$COOL[i] = 0}
      if(nestsubset$HVAC_STATE[i] =="heating") {nestsubset$HON[i] = 1} else {nestsubset$HON[i] = 0}
      if(nestsubset$HVAC_STATE[i] =="cooling") {nestsubset$CON[i] = 1} else {nestsubset$CON[i] = 0}
    }
    furnace_plot = ggplot(data = nestsubset) + 
      geom_area(aes(stpt,HEAT),fill="darkred", linetype = 0)+
      geom_area(aes(stpt,ECO),fill="forestgreen", linetype = 0)+
      geom_area(aes(stpt,COOL),fill="royalblue4", linetype = 0)+
      geom_area(aes(stpt,HON),fill="red", linetype = 0)+
      geom_area(aes(stpt,CON),fill="royalblue", linetype = 0)+
      geom_area(aes(stpt,NEST_FAN),fill="white", linetype = 0)+
      theme_dark() + 
      theme(axis.title.x=element_blank(),axis.title.y=element_text(color="white"),
            axis.text.y = element_blank(), axis.ticks.y = element_blank(), legend.position="right",
            panel.grid.major = element_blank(), panel.grid.minor = element_blank())
    furnace_plot
  })

  
  # renders for climate page --------------------------------------------------------------
  output$simpletemp <- renderPlotly({
    stemp = ggplot(data = subset(outdat,stpt>=(Sys.time()-(input$days*24*60*60))))+
      geom_line(aes(x=stpt,y=OUTSIDE_TEMP,color="maroon",text=stpt))+
      theme_dark()+labs(y="temp (F)")+scale_color_manual(values = c("#D62F27"))+
      theme(axis.title.x=element_blank(),axis.text.x=element_blank(),axis.ticks.x=element_blank(),
            legend.position="none",plot.margin = unit(c(0,0.2,0,1), "cm"))
  })
  output$simplehumid <- renderPlotly({
    shumid = ggplot(data = subset(outdat,stpt>=(Sys.time()-(input$days*24*60*60)) & OUTSIDE_HUMIDITY>10 & OUTSIDE_HUMIDITY<100))+
      geom_line(aes(x=stpt,y=OUTSIDE_HUMIDITY,color="green",text=stpt))+
      theme_dark()+labs(y="humidity (%)")+scale_color_manual(values = c("#D9EE8A"))+
      theme(axis.title.x=element_blank(),axis.text.x=element_blank(),axis.ticks.x=element_blank(),
            legend.position="none",plot.margin = unit(c(0,0.2,0,1), "cm"))
  })
  output$simplebarometer <- renderPlotly({
    sbarom = ggplot(data = subset(outdat,stpt>=(Sys.time()-(input$days*24*60*60))))+
      geom_line(aes(x=stpt,y=OUTSIDE_PRESSURE/6894.76,color="fuchia",text=stpt))+
      theme_dark()+labs(y="pressure (psi)")+scale_color_manual(values = c("#C2A4CF"))+
      theme(axis.title.x=element_blank(),axis.ticks.x=element_blank(),axis.text.y=element_text(angle=90),
            legend.position="none",plot.margin = unit(c(0,0.2,0,1), "cm"))
  })
  dbDisconnect(mydb)
  # render map from Dark Sky --------------------------------------------------------------
  output$darkmapframe <- renderUI({
    HTML('
    <style>
      .embed-container {
        position: relative;
        padding-bottom: 80%;
        height: 0;
        max-width: 100%;
      }
    </style>
    <iframe
        width="1500"
        height="900"
        frameborder="0"
        scrolling="no"
        marginheight="0"
        marginwidth="0"
        title="provPrepTest"
        src="https://darksky.net/map-embed/@temperature,38.411,-110.391,4.js?embed=true&timeControl=false&fieldControl=true&defaultField=precipitation_rate&defaultUnits=_inph">
    </iframe>
    ')
  })
}

shinyApp(ui, server)#======================================================================
