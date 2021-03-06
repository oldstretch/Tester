# File for co-ocurence analysis

ds.rpas.cooc <- readRDS(paste0("/Users/ulifretzen/Swaggathon/providedData/dt.rotterdamPas.RData"))


library(plyr)
library(reshape2)
library(ggplot2)
library(scales)
library(RColorBrewer)

# Analyze the distribution of activities based on type
activity.shares <- ddply(ds.rpas.cooc,
                         .(activity_type),
                         summarise,
                         nOccurances = length(activity_type))

activity.shares.ordered <- activity.shares[order(activity.shares$nOccurances,
                                                 decreasing = TRUE), ]

activity.shares.ordered$activity_type <- factor(activity.shares.ordered$activity_type)
activity.shares.ordered$n <- c(30:1)

# Calculate 1% of activities
one.percent.barrier <- sum(activity.shares.ordered$nOccurances) * 0.01

ggplot(activity.shares.ordered, aes(x = n, y = nOccurances)) +
  geom_point(color = "darkred") +
  geom_line(color = "red") +
  geom_line(y = one.percent.barrier) +
  labs(title = "Number of Observations per activity type",
       y = "Number of activity occurance", 
       x = "Activities (ranked in ascending order)") +
  scale_y_continuous(labels = comma) +
  theme(plot.title = element_text(hjust = 0.5, color = "#666666"),
        plot.subtitle = element_text(hjust = 0.5, color = "#666666"))
ggsave("/Users/ulifretzen/Swaggathon/results/Activity_Shares1.png")

activity.shares.ordered.above.barrier <- 
  activity.shares.ordered[activity.shares.ordered$nOccurances > one.percent.barrier, ]

activity.shares.ordered.above.barrier$percentage <- 
  round((activity.shares.ordered.above.barrier$nOccurances / sum(activity.shares.ordered$nOccurances)),5) * 100

activity.shares.above.barrier.index <- 
  which(ds.rpas.cooc$activity_type %in% activity.shares.ordered.above.barrier$activity_type)

# activity.shares.above.barrier <- ds.rpas.cooc[activity.shares.above.barrier.index, ]

ggplot(activity.shares.ordered.above.barrier, 
       aes(x = reorder(activity_type, percentage), 
           y = percentage, 
           fill = percentage)) +
  geom_bar(stat = "identity") +
  scale_fill_gradient(low = "#FFFFCC", high = "#B10026") +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_text(aes(label=percentage), vjust=0) +
  labs(title = "Share in total activity (%)", y = "Percentage of total activity", x = "Activity") +
  theme(plot.title = element_text(hjust = 0.5, color = "#666666"),
        plot.subtitle = element_text(hjust = 0.5, color = "#666666"))
ggsave("/Users/ulifretzen/Swaggathon/results/Activity_Shares2.png")

# Calculate number of activities per person
activities.pp <- ddply(ds.rpas.cooc, 
                       .(passH_nb), 
                       summarise, 
                       nActivities = length(passH_nb))

activities.pp.ordered <- activities.pp[order(activities.pp$nActivities), ]

# Conclusion: A large number of passholders are using the pass to participate in multiple events

# Calculate number of Passholders per nubmer of activities taken part in
passholders.per.nActivity <- ddply(activities.pp,
                                  .(nActivities),
                                  summarise,
                                  nPassHolders = length(nActivities))

passholders.per.nActivity.50.act <- head(passholders.per.nActivity, 50)

ggplot(passholders.per.nActivity.50.act, aes(x = nActivities, y = nPassHolders)) +
  geom_point(color = "darkred") +
  geom_line(color = "red") +
  labs(title = "Number of people per number of activities", 
       y = "Number of People", 
       x = "Number of Activities") +
  theme(plot.title = element_text(hjust = 0.5, color = "#666666"),
        plot.subtitle = element_text(hjust = 0.5, color = "#666666"))
ggsave("/Users/ulifretzen/Swaggathon/results/Count_People_per_Number_of_Activities.png")
# ggsave("/Users/ulifretzen/Swaggathon/results/Number_of_passholders_with_number_of_activities.png")


# Check for long tail
nActivity.under.5 <- sum(passholders.per.nActivity[1:5, ]$nPassHolders)
percentage.of.PassHolders.under.5.Activities <- nActivity.under.5 / sum(passholders.per.nActivity$nPassHolders)

nActivity.above.5 <- sum(passholders.per.nActivity[6:nrow(passholders.per.nActivity), ]$nPassHolders)
percentage.of.PassHolders.above.5.Activities <- nActivity.above.5 / sum(passholders.per.nActivity$nPassHolders)

df.activities <- data.frame(
  group = c("<= 5 activities", "> 5 activities"),
  value = c(percentage.of.PassHolders.under.5.Activities, 
            percentage.of.PassHolders.above.5.Activities)
)
head(df.activities)

# Create Bar Plot
pie.activities <- ggplot(df.activities, aes(x = "", y = value, fill = group))+
  geom_bar(width = 1, stat = "identity") +
  coord_polar("y", start = 0) +
  scale_fill_manual(values=c("#FEB24C", "#B10026")) +
  labs(title = "People with <= 5 activities vs. people with > 5 activities", 
       y = "", 
       x = "") +
  theme(axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        plot.title = element_text(hjust = 0.5, color = "#666666"),
        plot.subtitle = element_text(hjust = 0.5, color = "#666666")) +
  geom_text(aes(label = paste0(round(value*100, 1), "%")), position = position_stack(vjust = 0.5))

pie.activities

ggsave("/Users/ulifretzen/Swaggathon/results/People_with_5_or_less_activities.png")


prop.of.total.activities.by.rare.users <- sum(passholders.per.nActivity[1:5, ]$nActivities * 
                                                passholders.per.nActivity[1:5, ]$nPassHolders) /
  sum(passholders.per.nActivity$nActivities * 
        passholders.per.nActivity$nPassHolders)

prop.of.total.activities.by.frequent.users <- sum(passholders.per.nActivity[6:nrow(passholders.per.nActivity), ]$nActivities * 
                                                passholders.per.nActivity[6:nrow(passholders.per.nActivity), ]$nPassHolders) /
  sum(passholders.per.nActivity$nActivities * 
        passholders.per.nActivity$nPassHolders)

df.activities.total <- data.frame(
  group = c("<= 5 activities", "> 5 activities"),
  value = c(prop.of.total.activities.by.rare.users, 
            prop.of.total.activities.by.frequent.users)
)

head(df.activities.total)

pie.activities.total <- ggplot(df.activities.total, aes(x = "", y = value, fill = group))+
  geom_bar(width = 1, stat = "identity") +
  coord_polar("y", start = 0) +
  scale_fill_manual(values=c("#FEB24C", "#B10026")) +
  labs(title = "Total number of activities by people with <= 5 activities vs. people with > 5 activities", 
       y = "", 
       x = "") +
  theme(axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        plot.title = element_text(hjust = 0.5, color = "#666666"),
        plot.subtitle = element_text(hjust = 0.5, color = "#666666")) +
  geom_text(aes(label = paste0(round(value*100, 1), "%")), position = position_stack(vjust = 0.5))
pie.activities.total
ggsave("/Users/ulifretzen/Swaggathon/results/Total_activities_of_people_with_5_or_less_activities.png")

# It is worth looking at co-occurance

# Co-occurance analysis for activity type
df.rpas.wide <- dcast(ds.rpas.cooc, passH_nb ~ activity_type,
                      fun.aggregate = length)

rownames(df.rpas.wide) <- df.rpas.wide$passH_nb
df.rpas.wide <- df.rpas.wide[, -1]

df.rpas.wide <- as.data.frame(ifelse(df.rpas.wide >= 1, 1, 0))

# Find Co-occurence parameters
table(ds.rpas.cooc$activity_type, ds.rpas.cooc$activity_type)

# Create decision rules
library(arules)
myRules <- apriori(as.matrix(df.rpas.wide),
                   parameter = list(support = 0.01,
                                    confidence = 0.1,
                                    minlen = 2, maxlen = 2,
                                    target = "rules"))

inspect(myRules)
summary(myRules)
inspect(head(myRules, by ="lift", 10))

library(arulesViz)

# Create visualizations
plot(myRules)


plot(myRules, shading = "order",
     control = list(main = "Two-key plot"),
     pch = 19, col = rainbow (5)[c(1,3)])

plot(myRules , method = "grouped")

subRules <- head(sort(myRules, by = "lift"), 15)
plot(subRules , method = "graph")
ggsave("/Users/ulifretzen/Swaggathon/results/Co-occurance_network_graph.png")

# save script as pdf
knitr::stitch('Co-occurence.R')
