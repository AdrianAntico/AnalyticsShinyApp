\name{run_workstation}
\alias{run_workstation}
\alias{launch_workstation}
\title{Launch Analytics Workstation}
\usage{
run_workstation(host = "127.0.0.1", port = NULL, launch_browser = TRUE,
  options = list(), app_dir = NULL, launch.browser = NULL)
launch_workstation(prefer_desktop = TRUE, ...)
}
\arguments{
\item{host}{Host interface for the local Shiny server.}
\item{port}{Port for the local Shiny server. If \code{NULL}, the environment setting or Shiny default is used.}
\item{launch_browser}{Whether to open a browser after launch.}
\item{options}{Optional Shiny app options.}
\item{app_dir}{Deprecated compatibility argument. Ignored because installed package resources are authoritative.}
\item{launch.browser}{Deprecated compatibility spelling for \code{launch_browser}.}
\item{prefer_desktop}{Whether to prefer the installed desktop launcher when present.}
\item{...}{Additional arguments forwarded to \code{run_workstation()} when falling back to browser launch.}
}
\description{
Run or launch Analytics Workstation from installed package resources.
}
