#' Run \code{catch_em} with \code{shiny}
#'
#' @author Almog Simchon
#'
#' @import shiny
#' @export
catch_em_app <- function() {
  # Run the application
  shinyApp(ui = ui_gce, server = server_gce)
}

ui_gce <- fluidPage(

  # Application title
  titlePanel(paste0("Gotta Catch 'em All (v",packageVersion("cheatR"),')')),

  # Sidebar with a slider input for number of bins

  sidebarLayout(
    sidebarPanel(

      # img(src=paste0(dirname(rstudioapi::getSourceEditorContext()$path), "cheatrball.png"),
      #     align = "right", width="20%"),

      h3("Selected Documents"),

      fileInput("input_doc_list","Select Documents Files",
                multiple = TRUE),

      tableOutput("output_doc_list"),

      numericInput('n_grams',"n-grams (change only if you know what you're doing!)",value = 10, min = 2, width = '50%'),

      sliderInput("weight_range","Similarity coeffs to plot",min = 0,max = 1,value = c(0.4,1)),

      tags$div(class="header", checked=NA,

               list(
                 HTML("Want more info and Pokemon references?"),tags$a(href="https://github.com/mattansb/cheatR", "over here")
               )
      )
    ),

    # Show a plot of the generated distribution
    mainPanel(
      h3("Results"),

      DT::dataTableOutput("output_doc_matrix"),

      plotOutput('output_graph')
    )
  )
)

#' @import ggplot2
server_gce <- function(input, output) {
  first.word <- reactive({
    function(my.string){
      unlist(stringr::str_split(my.string, "[.]"))[[1]][1]
    }
  })

  catch_results <- reactive({
    if (is.null(input$input_doc_list))
      return(NA)

    res <- catch_em(input$input_doc_list$datapath, n_grams = input$n_grams)

    colnames(res$results) <- rownames(res$results) <- basename(input$input_doc_list$name)
    return(res)
  })

  output$output_doc_list <- renderTable({
    if (is.null(input$input_doc_list))
      return(data.frame())

    data.frame(Document = input$input_doc_list$name)
  })

  output$output_doc_matrix <- DT::renderDataTable({
    if (is.na(catch_results()))
      return(data.frame())

    for_mat <- summary(catch_results())

    round(for_mat,3)
  },
  rownames = TRUE, extensions = 'Buttons',
  options  = list(dom = 'Bfrtip',
                  buttons = c('copy', 'csv', 'excel', 'pdf', 'print'))
  )


  output$output_graph <- renderPlot({
    if (is.na(catch_results()))
      return(ggplot() + theme_void())

    graph_em(catch_results(),
             weight_range = input$weight_range) +
      theme_void()
  })
}
