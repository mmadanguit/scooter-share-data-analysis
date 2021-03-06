# Load relevant libraries ------------------------------------------------------
library(ggplot2)
library(rpart)
library(tidyverse)

# Import train and test data ---------------------------------------------------
dir <- "/home/marion/PVDResearch/Data/modelingData"
filenames <- c("trainData", "testData")
paths <- file.path(dir, paste(filenames, ".csv", sep = ""))

for (i in 1:length(filenames)) {
  assign(filenames[i], read.csv(paths[i]))
}

# Remove index column and convert weekday and season to factors
trainData <- trainData %>%
  select(-X) %>%
  mutate(weekday = as.factor(weekday),
         season = as.factor(season))
testData <- testData %>%
  select(-X) %>%
  mutate(weekday = as.factor(weekday),
         season = as.factor(season))

# Build regression tree --------------------------------------------------------
# Grow tree
fit <- rpart(sqrt(count)~.+sqrt(last_count)-last_count, data = select(trainData, -date), method = "anova")

printcp(fit) # Display the results
plotcp(fit) # Visualize cross-validation results
summary(fit) # Detailed summary of splits

# Plot and save tree
plot(fit, uniform = TRUE,
     main = "Regression Tree for Overall Usage")
text(fit, use.n = TRUE, all = TRUE, cex = .8)

# Create attractive postscript plot of tree
post(fit, file = "/home/marion/PVDResearch/Plots/treeFull.ps",
     title = "Regression Tree for Overall Usage")

# Prune the tree
pfit <- prune(fit, cp = 0.014) # from cptable   

# Plot the pruned tree
plot(pfit, uniform = TRUE,
     main = "Pruned Regression Tree for Overall Usage")
text(pfit, use.n = TRUE, all = TRUE, cex = .8)

# Create attractive postscript plot of tree
post(pfit, file = "/home/marion/PVDResearch/Plots/ptreeFull.ps",
     title = "Pruned Regression Tree for Overall Usage")

# Use tree to predict values on test data --------------------------------------
predict <- predict(pfit, newdata = testData)^2
rValue <- round(cor(predict, testData$count)^2, digits = 4)

# Create plots -----------------------------------------------------------------
# Calculate hourly average scooter usage
calculateAvg <- function(data) {
  data <- data %>%
    group_by(time) %>%
    summarise(count = mean(count))
  return(data)
}

createPlot <- function(predictedData, actualData, rValue) {
  # Adjust predicted data to match format of actual data
  predictedData <- predictedData %>%
    as_tibble() %>% 
    mutate(count = value,
           time = actualData$time)
  # Calculate hourly average scooter
  predictedAvg <- calculateAvg(predictedData) %>%
    mutate(id = "predicted")
  actualAvg <- calculateAvg(actualData) %>%
    mutate(id = "actual")
  # Merge predicted and actual hourly usage data
  avg <- rbind(predictedAvg, actualAvg)
  # Plot predicted vs actual hourly average scooter usage 
  plot <- ggplot(data = avg, aes(x = time, y = count, group = id)) +
    geom_line(aes(linetype = id)) + 
    labs(title = "Hourly Average Scooter Usage",
         subtitle = paste("Decision Tree Model",
                          "\nR-squared:", rValue)) +
    theme(axis.text.x = element_text(angle = 90))
  return(plot)
}

plot <- createPlot(predict, testData, rValue)

# Save plot 
dir <- "/home/marion/PVDResearch/Plots"
filename <- "Hourly_average_scooter_usage_decision_tree"
path <- file.path(dir, paste(filename, ".png", sep = ""))
ggsave(path)