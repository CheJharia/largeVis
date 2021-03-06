% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dendrogram.R
\name{as_dendrogram_hdbscan}
\alias{as_dendrogram_hdbscan}
\title{as_dendrogram_hdbscan}
\usage{
as_dendrogram_hdbscan(object)
}
\arguments{
\item{object}{An \code{hdbscan} object.}
}
\value{
A \code{dendrogram} object, where nodes have the following attributes:
\describe{
\item{'leaf'}{As in \code{\link[stats]{dendrogram}}.}
\item{'members'}{As in \code{\link[stats]{dendrogram}}.}
\item{'height'}{The \eqn{\lambda_{birth}} of the node or leaf.}
\item{'probability'}{The probability that the leaf is a true member of its assigned cluster.}
\item{'stability'}{The node's determined stability, taking into account child-node stabilities. Missing for leaves.}
\item{'selected'}{Whether the node was selected as a cluster.  Missing for leaves.  Note that when a node is selected,
all points under child branches are assigned to the same cluster.}
\item{'cluster'}{The cluster number, for reference against the \code{hdbscan} object.}
}
}
\description{
Convert an hdbscan object into dendrogram compatible with the \code{stats} package.
}
\note{
The hdbscan algorithm works by first building a hierarchy based on a minimal spanning tree, then consolidating nodes according to
rules in the algorithm. The algorithm then selects some of the consolidated nodes as clusters, deselecting others. For example, if Node A has children
B and C, the algorithm might select A, and then all points under A, B, and C would be assigned to the same cluster. Or, it might deselect A,
and select B and C instead. In that case, the nodes under B would be assigned to one cluster, the nodes under C to a different cluster, and nodes
under A but not B or C would not be assigned to any cluster. This function returns a dendrogram of the middle stage, the hierarchy of consolidated
nodes. Whether a node was selected as as cluster is an attribute of each node.
}
\examples{
data(iris)
vis <- largeVis(t(iris[,1:4]), K = 20, sgd_batches = 1)
hdbscanobj <- hdbscan(vis, minPts = 10, K = 5)
plot(as_dendrogram_hdbscan(hdbscanobj))
}

