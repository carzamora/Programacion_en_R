# Al parecer estas funciones ya no son necesarias acá, quizá antes no estaban en el paquete swirl 
# les agregué a las tres "_OLD" para que no se confundan, después creo que simplemente hay que eliminarlas
expr_creates_var_OLD <- function(correctName=NULL){
  e <- get("e", parent.frame())
  # TODO: Eventually make auto-detection of new variables an option.
  # Currently it can be set in customTests.R
  delta <- if(!customTests$AUTO_DETECT_NEWVAR){
    safeEval(e$expr, e)
  } else {
    e$delta
  }
  if(is.null(correctName)){
    results <- expectThat(length(delta) >= 1,
                          testthat::is_true(),
                          label=paste(deparse(e$expr),
                                      "no crea una variable."))
  } else {
    results <- expectThat(correctName %in% names(delta),
                          testthat::is_true(),
                          label=paste(deparse(e$expr),
                                      "no crea una variable llamada",
                                      correctName))
  }
  if(results$passed){
    e$newVar <- e$val
    e$newVarName <- names(delta)[1]
    e$delta <- mergeLists(delta, e$delta)
  } else {
    e$delta <- list()
  }
  return(results$passed)
}

# Returns TRUE if the user has calculated a value equal to that calculated by the given expression.
calculates_same_value_OLD <- function(expr){
  e <- get("e", parent.frame())
  # Calculate what the user should have done.
  eSnap <- cleanEnv(e$snapshot)
  val <- eval(parse(text=expr), eSnap)
  passed <- isTRUE(all.equal(val, e$val))
  if(!passed)e$delta <- list()
  return(passed)
}

omnitest_OLD <- function(correctExpr=NULL, correctVal=NULL, strict=FALSE){
  e <- get("e", parent.frame())
  # Trivial case
  if(is.null(correctExpr) && is.null(correctVal))return(TRUE)
  # Testing for correct expression only
  if(!is.null(correctExpr) && is.null(correctVal)){
    passed <- expr_identical_to(correctExpr)
    if(!passed)e$delta <- list()
    return(passed)
  }
  # Testing for both correct expression and correct value
  # Value must be character or single number
  valGood <- NULL
  if(!is.null(correctVal)){
    if(is.character(e$val)){
      valResults <- expectThat(e$val,
                               is_equivalent_to(correctVal, label=correctVal),
                               label=(e$val))
      if(is(e, "dev") && !valResults$passed)swirl_out(valResults$message)
      valGood <- valResults$passed
      # valGood <- val_matches(correctVal)
    } else if(!is.na(e$val) && is.numeric(e$val) && length(e$val) == 1){
      cval <- try(as.numeric(correctVal), silent=TRUE)
      valResults <- expectThat(e$val,
                               equals(cval, label=correctVal),
                               label=toString(e$val))
      if(is(e, "dev") && !valResults$passed)swirl_out(valResults$message)
      valGood <- valResults$passed
    }
  }
  exprGood <- ifelse(is.null(correctExpr), TRUE, expr_identical_to(correctExpr))
  if(valGood && exprGood){
    return(TRUE)
  } else if (valGood && !exprGood && !strict){
    swirl_out("Esa no es la expresión que estaba esperando pero funciona.")
    swirl_out("He ejecutado la expresión correcta en el caso que se necesite el resultado en una pregunta posterior.")
    eval(parse(text=correctExpr),globalenv())
    return(TRUE)
  } else {
    e$delta <- list()
    return(FALSE)
  }
}
