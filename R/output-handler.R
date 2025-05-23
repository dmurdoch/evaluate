#' Custom output handlers
#'
#' An `output_handler` handles the results of [evaluate()],
#' including the values, graphics, conditions. Each type of output is handled by
#' a particular function in the handler object.
#'
#' The handler functions should accept an output object as their first argument.
#' The return value of the handlers is ignored, except in the case of the
#' `value` handler, where a visible return value is saved in the output
#' list.
#'
#' Calling the constructor with no arguments results in the default handler,
#' which mimics the behavior of the console by printing visible values.
#'
#' Note that recursion is common: for example, if `value` does any
#' printing, then the `text` or `graphics` handlers may be called.
#'
#' @param source Function to handle the echoed source code under evaluation.
#'   This function should take two arguments (`src` and `expr`), and return
#'   an object that will be inserted into the evaluate outputs. `src` is the
#'   unparsed text of the source code, and `expr` is the complete input
#'   expression (which may have 0, 1, 2, or more components; see [parse_all()]
#'   for details).
#'
#'   Return `src` for the default evaluate behaviour. Return `NULL` to
#'   drop the source from the output.
#' @param text Function to handle any textual console output.
#' @param graphics Function to handle graphics, as returned by
#'   [recordPlot()].
#' @param message Function to handle [message()] output.
#' @param warning Function to handle [warning()] output.
#' @param error Function to handle [stop()] output.
#' @param value Function to handle the values returned from evaluation.
#'   * If it has one argument, it called on visible values.
#'   * If it has two arguments, it handles all values, with the second
#'     argument indicating whether or not the value is visible.
#'   * If it has three arguments, it will be called on all values, with the
#'     the third argument given the evaluation environment which is needed
#'     to look up print methods for S3 objects.
#' @param calling_handlers List of [calling handlers][withCallingHandlers].
#'   These handlers have precedence over the exiting handler installed
#'   by [evaluate()] when `stop_on_error` is set to 0.
#' @return A new `output_handler` object
#' @aliases output_handler
#' @export
new_output_handler <- function(
  source = identity,
  text = identity,
  graphics = identity,
  message = identity,
  warning = identity,
  error = identity,
  value = render,
  calling_handlers = list()
) {
  source <- match.fun(source)
  stopifnot(length(formals(source)) >= 1)
  text <- match.fun(text)
  stopifnot(length(formals(text)) >= 1)
  graphics <- match.fun(graphics)
  stopifnot(length(formals(graphics)) >= 1)
  message <- match.fun(message)
  stopifnot(length(formals(message)) >= 1)
  warning <- match.fun(warning)
  stopifnot(length(formals(warning)) >= 1)
  error <- match.fun(error)
  stopifnot(length(formals(error)) >= 1)
  value <- match.fun(value)
  stopifnot(length(formals(value)) >= 1)

  check_handlers(calling_handlers)

  structure(
    list(
      source = source,
      text = text,
      graphics = graphics,
      message = message,
      warning = warning,
      error = error,
      value = value,
      calling_handlers = calling_handlers
    ),
    class = "output_handler"
  )
}

check_handlers <- function(x) {
  if (!is.list(x)) {
    stop_bad_handlers()
  }

  if (!length(x)) {
    return()
  }

  names <- names(x)
  if (!is.character(names) || anyNA(names) || any(names == "")) {
    stop_bad_handlers()
  }

  for (elt in x) {
    if (!is.function(elt)) {
      stop_bad_handlers()
    }
  }
}
stop_bad_handlers <- function() {
  stop(simpleError(
    "`calling_handlers` must be a named list of functions.",
    call = call("new_output_handler")
  ))
}
