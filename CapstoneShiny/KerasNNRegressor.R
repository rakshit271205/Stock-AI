KerasNNRegressor <- function(
    x = x,
    y = y,
    cutoff = .9,
    validation_split = 1 - cutoff,
    loss = 'mae',
    optimizer = optimizer_rmsprop(),
    batch_size = 128,
    activation = 'relu',
    finalactivation = 'sigmoid',
    numberOfHiddenLayers = 1,
    useBias = FALSE,
    l1.units = 20,
    l2.units = 10,
    l3.units = 5,
    dropoutRate = 0.2,
    epochs = 10,
    forceClassifier = FALSE
) {
    
    # Package
    library(keras)
    
    # Data
    all <- data.frame(cbind(y, x))
    
    # Setup
    train_idx <- 1:round(cutoff*nrow(all),0)
    x_train <- as.matrix(all[train_idx, -1])
    y_train <- as.matrix(all[train_idx, 1])
    x_test <- as.matrix(all[-train_idx, -1])
    y_test <- as.matrix(all[-train_idx, 1])
    
    # Check levels for response
    number.of.levels <- nrow(plyr::count(y_train))
    num_classes <- number.of.levels
    
    # To prepare this data for training we one-hot encode the
    # vectors into binary class matrices using the Keras to_categorical() function
    # y_train <- to_categorical(y_train, number.of.levels)
    # y_test <- to_categorical(y_test, number.of.levels)
    
    # Defining the Model
    if (numberOfHiddenLayers == 0) {
        model <- keras_model_sequential()
        model %>%
            layer_dense(
                units = 1,
                input_shape = c(ncol(x_train)),
                activation = finalactivation,
                use_bias = useBias)
        summary(model)
    } else if (numberOfHiddenLayers == 1) {
        model <- keras_model_sequential()
        model %>%
            layer_dense(units = l1.units, activation = activation, input_shape = c(ncol(x_train))) %>%
            layer_dropout(dropoutRate) %>%
            layer_dense(units = 1, activation = finalactivation)
        summary(model)
    } else if (numberOfHiddenLayers == 2) {
        model <- keras_model_sequential()
        model %>%
            layer_dense(units = l1.units, activation = activation, input_shape = c(ncol(x_train))) %>%
            layer_dropout(dropoutRate) %>%
            layer_dense(units = l2.units, activation = activation, use_bias = useBias) %>%
            layer_dropout(dropoutRate) %>%
            layer_dense(units = 1, activation = finalactivation)
        summary(model)
    } else if (numberOfHiddenLayers == 3) {
        model <- keras_model_sequential()
        model %>%
            layer_dense(units = l1.units, activation = activation, input_shape = c(ncol(x_train))) %>%
            layer_dropout(dropoutRate) %>%
            layer_dense(units = l2.units, activation = activation, use_bias = useBias) %>%
            layer_dropout(dropoutRate) %>%
            layer_dense(units = l3.units, activation = activation, use_bias = useBias) %>%
            layer_dropout(dropoutRate) %>%
            layer_dense(units = 1, activation = finalactivation)
        summary(model)
    } else {
        print("============== WARNING ==============")
        print("Input value for [numberOfHiddenLayers] must be 0, 1, 2, or 3.")
        print("Since none of the values above are entered, the default is set to 1.")
        print("=====================================")
    } # Done with model
    
    
    # Next, compile the model with appropriate loss function, optimizer, and metrics:
    model %>% compile(
        loss = loss,
        optimizer = optimizer,
        metrics = c(loss) )
    
    # Training and Evaluation
    history <- model %>% fit(
        x_train, y_train,
        epochs = epochs,
        batch_size = batch_size,
        validation_split = validation_split
    ); plot(history)
    
    # Evaluate the model's performance on the test data:
    scores = model %>% evaluate(x_test, y_test)
    
    # Generate predictions on new data:
    if (forceClassifier == TRUE) {
        y_test_hat <- model %>% predict_proba(x_test)
        y_test_binary <- ifelse(y_test_hat > mean(y_test_hat), 1, 0)
        confusion.matrix <- table(Y_Hat = y_test_binary, Y = y_test)
        test.acc <- sum(diag(confusion.matrix))/sum(confusion.matrix)
        all.error <- plyr::count(y_test - cbind(y_test_binary))
        y_test_eval_matrix <- cbind(
            y_test=y_test,
            y_test_hat=y_test_binary,
            y_test_hat_raw=y_test_hat )
        
        # AUC/ROC
        if ((num_classes == 2) && (nrow(plyr::count(y_test_hat)) > 1)) {
            AUC_test <- pROC::roc(c(y_test), c(y_test_hat))
        } else {
            AUC_test <- c("Estimate do not have enough levels.")
        }
        
        # Output
        result <- list(
            Confusion.Matrix = confusion.matrix,
            Confusion.Matrix.Pretty = knitr::kable(confusion.matrix),
            Testing.Accuracy = test.acc,
            All.Types.of.Error = all.error,
            Test_AUC = AUC_test
        )
    } else {
        y_test_hat <- model %>% predict_proba(x_test)
        MSE_test <- mean((y_test - y_test_hat)^2)
        y_test_eval_matrix <- cbind(
            y_test=y_test,
            y_test_hat_raw=y_test_hat )
        
        # Output
        result <- list(
            MSE_test = MSE_test
        )
    }
    
    # Return
    return(
        list(
            Model = list(model = model, scores = scores),
            x_train = x_train,
            y_train = y_train,
            x_test = x_test,
            y_test = y_test,
            y_test_hat = y_test_hat,
            y_test_eval_matrix = y_test_eval_matrix,
            Training.Plot = plot(history),
            Result = result
        )
    )
}