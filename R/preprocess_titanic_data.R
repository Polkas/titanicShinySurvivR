#' Preprocess Titanic Data
#'
#' Internal function for the Titanic SurvivR Shiny app. Cleans and transforms Titanic
#' datasets for model training and testing.
#'
#' @param train_data Raw training data.
#' @param test_data Raw test data.
#'
#' @keywords internal
#' @noRd
preprocess_titanic_data <- function(train_data, test_data) {

  required_cols <- c("Survived", "Pclass", "Sex", "Age", "SibSp", "Parch", "Fare", "Embarked", "Cabin")

  train_data <- train_data[required_cols]
  test_data <- test_data[required_cols]

  train_data$Survived <- as.factor(train_data$Survived)
  train_data$Pclass <- as.factor(train_data$Pclass)
  train_data$Sex <- as.factor(train_data$Sex)
  train_data$Embarked <- as.factor(train_data$Embarked)
  train_data$Fare <- as.numeric(train_data$Fare)
  train_data$Age <- as.numeric(train_data$Age)

  train_age_median <- median(train_data$Age, na.rm = TRUE)
  train_fare_median <- median(train_data$Fare, na.rm = TRUE)

  general_recipe <- recipes::recipe(Survived ~ ., data = train_data) %>%
    recipes::step_impute_median(SibSp, Parch) %>%
    recipes::step_impute_mode(Embarked, Pclass) %>%
    recipes::step_mutate(HaveCabin = as.factor(ifelse(is.na(Cabin), 0, 1))) %>%
    recipes::step_mutate(CabinDeck = dplyr::if_else(is.na(Cabin), "U", substr(Cabin, 1, 1))) %>%
    recipes::step_mutate(CabinDeck = factor(CabinDeck))  %>%
    recipes::step_mutate(FamilySize = SibSp + Parch + 1) %>%
    recipes::step_mutate(IsAlone = dplyr::if_else(FamilySize == 1, 1, 0)) %>%
    recipes::step_rm(Cabin)

  prepped_recipe <- suppressWarnings(recipes::prep(general_recipe, training = train_data))
  train_prepped <- suppressWarnings(recipes::bake(prepped_recipe, new_data = train_data))
  test_prepped <- suppressWarnings(recipes::bake(prepped_recipe, new_data = test_data))

  train_prepped$Age[is.na(train_prepped$Age)] <- train_age_median
  test_prepped$Age[is.na(test_prepped$Age)] <- train_age_median
  train_prepped$Fare[is.na(train_prepped$Fare)] <- train_fare_median
  test_prepped$Fare[is.na(test_prepped$Fare)] <- train_fare_median

  return(list(train = train_prepped,
              test = test_prepped,
              recipe = prepped_recipe))
}
