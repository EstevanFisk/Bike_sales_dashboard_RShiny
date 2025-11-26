# DEMAND FORECAST ANALYSIS ----

# 1.0 LIBRARIES -----

# Core
library(tidyverse)
library(tidyquant)

# Interactive Visualizations
library(plotly)

# Modeling Libraries
library(parsnip)
library(timetk)

# Database
library(odbc)
library(RSQLite)


# 2.0 PROCESSED DATA ----
con <- dbConnect(RSQLite::SQLite(), "../data/bikes_database.db")

bikes_tbl <- tbl(con, "bikes")
bikeshops_tbl <- tbl(con, "bikeshops")
orderlines_tbl <- tbl(con, "orderlines")

processed_data_tbl <- orderlines_tbl %>%
    left_join(bikeshops_tbl, by = c("customer.id" = "bikeshop.id")) %>%
    left_join(bikes_tbl, by = c("product.id" = "bike.id")) %>%
    mutate(extended_price = quantity * price) %>%
    collect()

processed_data_tbl <- processed_data_tbl %>%    
    mutate(order.date = ymd(order.date)) %>%
    separate(location, into = c("city", "state"), sep = ", ") %>%
    
    separate(description, 
             into = c("category_1", "category_2", "frame_material"),
             sep = " - ") %>%
    
    select(order.date, order.id, order.line, state, quantity, price,
           extended_price, category_1:frame_material, bikeshop.name)

dbDisconnect(con)


# 3.0 TIME SERIES AGGREGATION ----

# 3.1 DATA MANIPULATION ----
time_unit <- "quarter"

time_plot_tbl <- processed_data_tbl %>%
    
    mutate(date = floor_date(order.date, unit = time_unit)) %>%
    
    group_by(date) %>%
    summarize(total_sales = sum(extended_price)) %>%
    ungroup() %>%
    
    mutate(label_text = str_glue("Date: {date}
                                 Revenue: {scales::dollar(total_sales)}"))

time_plot_tbl

# 3.2 FUNCTION ----

# TODO - aggregate_time_series() 

aggregate_time_series <- function(data, time_unit = "month") {
    
    output_tbl <- data %>%
        
        mutate(date = floor_date(order.date, unit = time_unit)) %>%
        
        group_by(date) %>%
        summarize(total_sales = sum(extended_price)) %>%
        ungroup() %>%
        
        mutate(label_text = str_glue("Date: {date}
                                 Revenue: {scales::dollar(total_sales)}"))
    
    return(output_tbl)
    
}

processed_data_tbl %>%
    aggregate_time_series(time_unit = "day")




# 3.3 TIME SERIES PLOT ----

data <- processed_data_tbl %>%
    aggregate_time_series("month")

g <- data %>%
    
    ggplot(aes(date, total_sales)) +
    
    geom_line(color = "#2c3e50") +
    geom_point(aes(text = label_text), color = "#2c3e50", size = 0.1) +
    geom_smooth(method = "loess", span = 0.2) +
    
    theme_tq() +
    expand_limits(y = 0) +
    scale_y_continuous(labels = scales::dollar_format()) +
    labs(x = "", y = "")


ggplotly(g, tooltip = "text")


# 3.4 FUNCTION ----

# TODO - MAKE FUNCTION 

plot_time_series <- function(data) {
    
    g <- data %>%
        
        ggplot(aes(date, total_sales)) +
        
        geom_line(color = "#2c3e50") +
        geom_point(aes(text = label_text), color = "#2c3e50", size = 0.1) +
        geom_smooth(method = "loess", span = 0.2) +
        
        theme_tq() +
        expand_limits(y = 0) +
        scale_y_continuous(labels = scales::dollar_format()) +
        labs(x = "", y = "")
    
    
    ggplotly(g, tooltip = "text")
}


processed_data_tbl %>%
    aggregate_time_series(time_unit = "quarter") %>%
    plot_time_series()




# 4.0 FORECAST -----

# NOTE:  New Methods of Time Series Forecasting: Time Series forecasting has traditionally 
# been performed using ARIMA, Holt Winters, State Space Models, etc.  We will deviate from
# this approach to show a newer technique leveraging Machine Learning.

# Why ML?  Reason 1: Speed- Forecasting speed of daily, weekly, and even monthly time
# series can be slow with autoregressive techniques.

# Reason 2: Better Forecasts on the Fly- ML techniques are very good at detecting patterns in
# data.  Sub-dayily, daily, weekly, monthly, and even quarterly data tend to have seasonality.
# ML will pick this up very well without much tuning.
# ARIMA requires a lot of tuning and experience to get good results.  Worse, tuning is different
# depending on the time series.  This makes models NOT flexible to different data sets and time
# series aggregations (which is what we need because who knows what our users will select from our inputs).




# 4.1 SETUP TRAINING DATA AND FUTURE DATA ----

# TODO - timetk

# timetk will help us quickly understand our time series and expand the time stamps into
# features we can use for machine learning.

data <- processed_data_tbl %>%
    aggregate_time_series(time_unit = "year")

# tk_index() Extracts the time series index, which is the time stamp information, as a vector.
# shortcut for pull(date_column).

data %>% tk_index() %>%
    # tk_get_timeseries_signature() convers the timestamp information (index) into a data frame of key
    # information about that time series index.  I call this signature, because it's unique to the
    # pattern within the time series you are interested.
    
    tk_get_timeseries_signature()



# tk_get_timeseries_summary() Returns a data frame with summary information about the time series index.
# for Units vs scale:
# Units- Think of the units as the smallest part of the time stamp.  For "2011-01-01" the unit is days.
# Scale- Think of scale as a measure between two observations.  If every observation is spaced 1 month apart,
# the scale is month.
data %>% tk_index() %>% tk_get_timeseries_summary()


# tk_get_timeseries_unit_frequency() is a helper function which returns the number of seconds between
# different time scales.  Anything less than the value gets the preceding time scale. (e.g. if 
# median diff= 50, the scale returned is "sec" for seconds)
tk_get_timeseries_unit_frequency()



# tk_get_timeseries_variables() returns the column name of the time stamp data
data %>% tk_get_timeseries_variables()


# tk_augment_timeseries_signature() is a helper function to simplify the steps to adding time series signature
# columns to a data frame.
data %>% tk_augment_timeseries_signature()



train_tbl <- data %>%
    tk_augment_timeseries_signature()


# Future data
future_data_tbl <- data %>%
    tk_index() %>%
    # tk_make_future_timeseries() helps in making future time stamps that extend at the
    # same periodicity of the current time stamp scale.
    tk_make_future_timeseries(length_out = 12, inspect_weekdays = TRUE, inspect_months = TRUE) %>%
    tk_get_timeseries_signature()




# 4.2 MACHINE LEARNING ----

# TODO - XGBoost using parsnip

# NOTE: Hyperparameter Tuning for Time Series:  This will be challenging for us given that the
# user can input almost any combination of values for customer, bike type, period aggregation, etc.
# The models will need to be trained real-time, so we are going to make several assumptions to achieve
# a good enough model.

# Validation and accuracy reporting:  For the purposes of the course, we will visually evaluate
# the adequacy of the model on various time aggregations.
# With that said, a future course on time series will explore time series backtesting and validation in detail.

# Assumptions for Parameters Used:  We will make the assumption that any XGBOOST model with the following
# parameters will be a good starting point.
# We will use knowledge from the 101 course on parameters to select values that will be robust to many time series.
# Refer to page 2 of the ML Cheat Sheet for parameter selection.

# Parameters used here:  mtry = 20: how many columns to use, using all columns may overfit, so reduce to 2/3
# of columns.
# trees = 500, used to keep speed fast for real-time training.
# min n= 3: Each node must have 3 values minimum
# tree_depth = 8: Max tree depth is 8 levels to prevent overfitting
# learn_rate = 0.01: make sure we find a high accuracy solution
# loss_reduction = 0.01: Each split must improve the model by 1% to make a split.

seed <- 123
set.seed(seed)
model_xgboost <- boost_tree(
        mode = "regression",
        mtry = 20,
        trees = 500,
        min_n = 3,
        tree_depth = 8,
        learn_rate = 0.01,
        loss_reduction = 0.01
        ) %>%
    set_engine(engine = "xgboost") %>%
    fit.model_spec(total_sales ~ ., data = train_tbl %>% select(-date, -label_text, -diff))




# 4.3 MAKE PREDICTION & FORMAT OUTPUT ----

# TODO - predict

future_data_tbl

prediction_tbl <- predict(model_xgboost, new_data = future_data_tbl) %>%
    bind_cols(future_data_tbl) %>%
    select(.pred, index) %>%
    rename(total_sales = .pred,
           date = index) %>%
    mutate(label_text = str_glue("Date: {date}\nRevenue: {scales::dollar(total_sales)}")) %>%
    add_column(key = "Prediction")


output_tbl <- data %>%
    add_column(key = "Actual") %>%
    bind_rows(prediction_tbl)

output_tbl




# 4.4 FUNCTION ----

# TODO - generate_forecast()


generate_forecast <- function(data, n_future = 12, seed = NULL) {
    
    train_tbl <- data %>%
        tk_augment_timeseries_signature()
    
    
    # Future data
    future_data_tbl <- data %>%
        tk_index() %>%
        # tk_make_future_timeseries() helps in making future time stamps that extend at the
        # same periodicity of the current time stamp scale.
        tk_make_future_timeseries(length_out = n_future, inspect_weekdays = TRUE, inspect_months = TRUE) %>%
        tk_get_timeseries_signature()
    
    time_scale <- data %>%
        tk_index() %>%
        tk_get_timeseries_summary() %>%
        pull(scale)
    
    if(time_scale == "year"){
        
        # Setup linear regression for year
        model <- linear_reg(mode = "regression") %>%
            set_engine(engine = "lm") %>%
            # you can use either fit or fit.model_spec(), the latter shows you the arguments.
            fit.model_spec(formula = total_sales ~ ., data = train_tbl %>% select(total_sales, index.num))
        
    } else {
        
        seed <- seed
        set.seed(seed)
        model <- boost_tree(
                mode = "regression",
                mtry = 20,
                trees = 500,
                min_n = 3,
                tree_depth = 8,
                learn_rate = 0.01,
                loss_reduction = 0.01
                ) %>%
                 set_engine(engine = "xgboost") %>%
                 fit.model_spec(total_sales ~ ., data = train_tbl %>% select(-date, -label_text, -diff))
    }
    
    

    
    prediction_tbl <- predict(model, new_data = future_data_tbl) %>%
        bind_cols(future_data_tbl) %>%
        select(.pred, index) %>%
        rename(total_sales = .pred,
               date = index) %>%
        mutate(label_text = str_glue("Date: {date}\nRevenue: {scales::dollar(total_sales)}")) %>%
        add_column(key = "Prediction")
    
    
    output_tbl <- data %>%
        add_column(key = "Actual") %>%
        bind_rows(prediction_tbl)
    
    return(output_tbl)
}


# test function through workflow process
processed_data_tbl %>%
    aggregate_time_series(time_unit = "month") %>%
    generate_forecast(n_future = 12, seed = 123)





# 5.0 PLOT FORECAST ----

# 5.1 PLOT ----

# TODO - plot

data <- processed_data_tbl %>%
    aggregate_time_series(time_unit = "month") %>%
    generate_forecast(n_future = 12, seed = 123)


g <- data %>%
    ggplot(aes(x= date, y = total_sales, color = key)) +
    
    geom_line() +
    # Hack for tool tip text later
    geom_point(aes(text = label_text), size = 0.1) +
    geom_smooth(method = "loess", span = 0.2) +
    
    theme_tq() +
    scale_color_tq() +
    scale_y_continuous(labels = scales::dollar_format()) +
    labs(x = "", y = "")
    

ggplotly(g, tooltip = "text")





# 5.2 FUNCTION ----

# TODO - plot_forecast()



data <- processed_data_tbl %>%
    aggregate_time_series(time_unit = "year") %>%
    generate_forecast(n_future = 1, seed = 123)


plot_forecast <- function(data) {
    
    # Yearly - LM Smoother
    
    time_scale <- data %>%
        tk_index() %>%
        tk_get_timeseries_summary() %>%
        pull(scale)
    
    
    
    # If only 1 prediction - convert to points
    n_predictions <- data %>%
        filter(key == "Prediction") %>%
        nrow()
    
    
    
    g <- data %>%
        ggplot(aes(x= date, y = total_sales, color = key)) +
        
        geom_line() +
        # Hack for tool tip text later
        # removed geom_point as we updated to incorporate for one point option below
        #geom_point(aes(text = label_text), size = 0.1) +
        # removed smoother here as we updated to incorporate lm as well.
        #geom_smooth(method = "loess", span = 0.2) +
        
        theme_tq() +
        scale_color_tq() +
        scale_y_continuous(labels = scales::dollar_format()) +
        expand_limits(y = 0) +
        labs(x = "", y = "")
    
    # Yearly - LM Smoother
    if(time_scale == "year") {
        g <- g +
            geom_smooth(method = "lm")
    } else {
        g <- g +
            geom_smooth(method = "loess", span = 0.2)
    }
    
    # Only 1 prediction
    if (n_predictions == 1) {
        g <- g +
            geom_point(aes(text = label_text), size = 1)
    } else {
        g <- g +
            geom_point(aes(text = label_text), size = 0.01)
    }
    
    
    ggplotly(g, tooltip = "text")
}


# test with pipeline:
processed_data_tbl %>%
    aggregate_time_series(time_unit = "month") %>%
    generate_forecast(n_future = 12, seed = 123) %>%
    plot_forecast()




# 6.0 SAVE FUNCTIONS ----

dump(c("aggregate_time_series", "plot_time_series", "generate_forecast", "plot_forecast"), 
     file = "../scripts/04_demand_forecast.R")
