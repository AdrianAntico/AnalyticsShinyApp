\name{workstation_diagnostics}
\alias{workstation_diagnostics}
\alias{workstation_installation_info}
\alias{qa_package_distribution}
\alias{qa_electron_distribution}
\title{Analytics Workstation installation diagnostics}
\usage{
workstation_diagnostics(create = TRUE)
workstation_installation_info(create = TRUE)
qa_package_distribution()
qa_electron_distribution()
}
\arguments{
\item{create}{Whether to create missing per-user diagnostic directories before checking them.}
}
\description{
Return structured installation, dependency, path, launcher, and Electron readiness diagnostics.
}
