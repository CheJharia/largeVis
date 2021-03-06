cutoptics <- function(x) {
	clust <- 1
	eps <- x$eps
	minPts <- x$minPts
	clusters <- rep(0, length(x$order))
	for (i in 1:length(x$order)) {
		thisNode <- x$order[i]
		if (is.na(x$predecessor[thisNode]) | x$reachdist[thisNode] > eps) clust <- clust + 1
		clusters[thisNode] <- clust
	}
	badClusters <- which(tabulate(clusters) < minPts)
	clusters[clusters %in% badClusters] <- NA
	remainders <- unique(clusters)
	match(clusters, remainders)
}

context("dbscan-iris")

set.seed(1974)
data(iris)
dat <- as.matrix(iris[, 1:4])
dupes <- which(duplicated(dat))
dat <- dat[-dupes, ]
dat <- t(dat)
K <- 147
neighbors <- randomProjectionTreeSearch(dat, K = K, tree_threshold = 80, n_trees = 10,  max_iter = 4, threads = 2, verbose = FALSE)
edges <- buildEdgeMatrix(data = dat,
												 neighbors = neighbors,
												 verbose = FALSE)

test_that("dbscan doesn't crash on iris", {
	expect_silent(lv_dbscan(edges = edges, neighbors = neighbors, eps = 1, minPts = 10, verbose = FALSE))
})

load(system.file(package = "largeVis", "testdata/irisdbscan.Rda"))

test_that("dbscan matches iris", {
	dbclusters <- lv_dbscan(edges = edges, neighbors = neighbors, eps = 1, minPts = 10, verbose = FALSE)
	expect_lte(sum(dbclusters$cluster != irisclustering$cluster), 1)
})

test_that("dbscan works with largeVis objects", {
	vis <- largeVis(dat, sgd_batches = 1, threads = 2)
	expect_silent(cl <- lv_dbscan(vis, eps = 1, minPts = 10))
	expect_lte(sum(cl$cluster != irisclustering$cluster), 1)
})

context("dbscan-jain")

test_that("dbscan matches dbscan on jain when the neighborhoods are complete", {
	skip_on_cran()
	skip_on_travis()
	load(system.file(package = "largeVis", "testdata/jaindata.Rda"))
	jainclusters <- lv_dbscan(edges = jaindata$edges, neighbors = jaindata$neighbors, eps = 2.5, minPts = 10, verbose = FALSE)
	expect_equal(jainclusters$cluster, jaindata$dbclusters25$cluster)
})

context("optics-iris")

set.seed(1974)
data(iris)
dat <- as.matrix(iris[, 1:4])
dupes <- which(duplicated(dat))
dat <- dat[-dupes, ]
dat <- t(dat)
K <- 147
neighbors <- randomProjectionTreeSearch(dat, K = K, tree_threshold = 80, n_trees = 10,  max_iter = 4, threads = 2, verbose = FALSE)
edges <- buildEdgeMatrix(data = dat,
												 neighbors = neighbors,
												 verbose = FALSE)

test_that("optics doesn't crash on iris", {
  expect_silent(lv_optics(edges = edges, neighbors = neighbors, eps = 10, minPts = 10, useQueue = FALSE, verbose = FALSE))
})

load(system.file(package = "largeVis", "testdata/irisoptics.Rda"))
opclusters <- lv_optics(edges = edges, neighbors = neighbors, eps = 1, minPts = 10,  useQueue = FALSE, verbose = FALSE)

test_that("optics matches optics core infinities", {
	expect_equal(which(is.infinite(opclusters$coredist)), which(is.infinite(irisoptics$coredist)))
})

test_that("optics matches optics core dist not infinities", {
	expect_equal(opclusters$coredist[!is.infinite(opclusters$coredist)], irisoptics$coredist[!is.infinite(irisoptics$coredist)])
})

test_that("opticis iris cut to dbscan matches dbscan", {
	cl <- cutoptics(opclusters)
	dbclusters <- lv_dbscan(edges = edges, neighbors = neighbors, eps = 1, minPts = 10, verbose = FALSE)
	expect_equal(cl, dbclusters$cluster)
})

test_that("optics works with largeVis objects", {
	vis <- largeVis(dat, threads = 2, sgd_batches = 1)
	expect_silent(cl <- lv_optics(vis, eps = 1, minPts = 10))
	expect_equal(cl$coredist[!is.infinite(cl$coredist)], irisoptics$coredist[!is.infinite(irisoptics$coredist)])
})

context("optics-jain")

load(system.file(package = "largeVis", "testdata/jaindata.Rda"))
jainclusters <- lv_optics(edges = jaindata$edges,
													neighbors = jaindata$neighbors,
													eps = 2.5, minPts = 5, useQueue = FALSE,
													verbose = FALSE)

test_that("optics matches optics core on jain when the neighborhoods are complete", {
	expect_equal(is.infinite(jainclusters$coredist), is.infinite(jaindata$optics$coredist))
	selections <- !is.infinite(jainclusters$coredist) & !is.infinite(jaindata$optics$coredist)
	expect_equal(jainclusters$coredist[selections], jaindata$optics$coredist[selections])
})

test_that("optics matches dbscan on jain when the neighborhoods are complete", {
	cl <- cutoptics(jainclusters)
	expect_lte(sum(cl != (jaindata$dbclusters5$cluster + 1)), 2)
})

test_that("optics matches optics reachdist on jain when the neighborhoods are complete", {
	expect_equal(is.infinite(jainclusters$reachdist), is.infinite(jaindata$optics$reachdist))
})

context("optics-elki")

load(system.file("testdata/opttest.Rda", package = "largeVis"))

x <- opttest$test_data
neighbors <- randomProjectionTreeSearch(t(opttest$test_data), K = 399, tree_threshold = 100, max_iter = 10, seed = 1974)
edges <- buildEdgeMatrix(t(opttest$test_data), neighbors = neighbors, threads = 1)

eps <- .1
eps_cl <- .1
minPts <- 10
res <- lv_optics(edges, neighbors, eps = eps, useQueue = FALSE,  minPts = minPts)

test_that("optics output format is correct", {
	expect_identical(length(res$order), nrow(x))
	expect_identical(length(res$reachdist), nrow(x))
	expect_identical(length(res$coredist), nrow(x))
	expect_identical(res$eps, eps)
	expect_identical(res$minPts, minPts)
})

test_that("optics coredist matches elki", {
	expect_equal(res$coredist, opttest$elkiopt$coredist)
})


test_that("optics result matches elki after cut", {
	optcut <- cutoptics(res)
	refcut <- cutoptics(opttest$elkiopt)
	expect_equal(optcut, refcut)
})