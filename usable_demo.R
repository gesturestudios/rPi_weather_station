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
                                       menuItem("Bills",   tabName = "bills",  icon = icon("dollar"),
                                                menuSubItem("Utility bills",tabName = "utility"),
                                                menuSubItem("Home improvement",tabName = "homeimp")
                                       ),
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
                                              background = "navy",width = "450px", height = "200px",
                                              img(src="http://www.hamqsl.com/solarpich.php")
                                            )
                                            
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
      value=45,
      subtitle="outside",
      color=textcolor(45)
    )
  })
  output$inside    <- renderValueBox({
    valueBox(
      icon("thermometer-4"),
      value=68,
      subtitle="inside",
      color=textcolor(68)
    )
  })
  output$climate_status    <- renderValueBox({
    valueBox(
      subtitle = "thermostat set to",
      value=67,
      icon("fire"),
      color="red"
    )
  })
  

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
