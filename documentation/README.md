RCTD and C-SIDE Documentation
================
Dylan Cable
12/22/2021

## Introduction

Here, we will provide additional documentation on the *spacexr* R
package. Other sources of spacexr documentation include the
[vignettes](https://github.com/dmcable/spacexr/tree/master/vignettes)
and the [Github issues](https://github.com/dmcable/spacexr/issues).
Another great option for help on particular functions is to use the R
manual files, which can be accessed with `?` or `help`. For example:

``` r
?run.RCTD
?run.CSIDE.single
```

This page is intended to be a resource for frequently asked questions,
tips and tricks, and odds and ends that are not addressed in other
sources. Here, we will not be running code on real data as that is
covered by the vignettes.

Terminology:

-   *pixel*, synonymous with *spot* or *bead*, a measurement unit for
    spatial transcriptomics data that measures gene expression at a
    fixed location. We do not use the term *cell* because single
    *pixels* can sometimes contain mixtures of multiple cells.
-   *explanatory variable*, synonymous with *covariate* or *predictive
    variable*, a vector with values at each pixel that can be used to
    explain gene expression.
-   *design matrix*, the matrix containing all explanatory variables for
    explaining gene expression. Each explanatory variable appears as a
    single column in the matrix.

## Inputting data

### Creating a RCTD object

Both RCTD and C-SIDE require the construction of an `RCTD` object. In
order to construct an RCTD object, you should use the `create.RCTD`
function:

``` r
myRCTD <- create.RCTD(spaceRNA, reference)
```

Here, `spaceRNA` represents the spatial transcriptomics dataset as a
`SpatialRNA` object, described below. Also, `reference` is a `Reference`
object (also described below) containing annotated cell types from a
scRNA-seq dataset.

Important options for the `create.RCTD` function include (see
`?create.RCTD` for details):

-   `max_cores`: (default 4) number of cores used for running RCTD (and
    later C-SIDE). A rule of thumb is to use half the maximum number of
    cores on your machine.
-   `MAX_MULTI_TYPES`: (default 4) if using RCTD multi mode, the maximum
    number of cell types per pixel.

In general, we will only highlight a subset of parameters/features, but
curious users should always use the `help` function to find more
information about the capabilities of a function.

We will now discuss how to create the `Reference` and `SpatialRNA`
objects needed above.

### Creating a Reference object

The reference is created using the RCTD `Reference` constructor
function:

``` r
reference <- Reference(counts, cell_types, nUMI)
```

The function `Reference` requires 3 parameters: <br/> 1. `counts`: A
matrix (or dgCmatrix) representing Digital Gene Expression (DGE).
Rownames should be genes and colnames represent barcodes/cell names.
Counts should be untransformed count-level data. <br/> 2.
`cell_types`:  
A named (by cell barcode) factor of cell type for each cell. The
‘levels’ of the factor would be the possible cell type identities. <br/>
3. `nUMI`:  
Optional, a named (by cell barcode) list of total counts or UMI’s
appearing at each pixel. If not provided, nUMI will be assumed to be the
total counts appearing on each pixel. <br/>

An option for the `Reference` function is `n_max_cells` (default 10000),
which determines the maximum number of cells used from each cell type.

### Creating a SpatialRNA object

Similarly to the reference, first load the data into R, and then pass
the data into the RCTD `SpatialRNA` constructor function.

``` r
spaceRNA <- SpatialRNA(coords, counts, nUMI)
```

This function requires 3 parameters: <br/> 1. coords: A numeric
data.frame (or matrix) representing the spatial pixel locations.
rownames are barcodes/pixel names, and there should be two columns for
‘x’ and for ‘y’.<br/> 2. counts: A matrix (or dgCmatrix) representing
Digital Gene Expression (DGE). Rownames should be genes and colnames
represent barcodes/pixel names. Counts should be untransformed
count-level data. <br/> 3. nUMI:  
Optional, a named (by pixel barcode) list of total counts or UMI’s
appearing at each pixel. If not provided, nUMI will be assumed to be the
total counts appearing on each pixel. <br/>

## RCTD

### Running RCTD

We now show how to run RCTD to assign cell types.

``` r
myRCTD <- run.RCTD(myRCTD, doublet_mode = 'doublet')
```

Here, we have three options for `doublet_mode`: *`doublet mode`: at most
1-2 cell types per pixel, recommended for high spatial resolution
technologies such as Slide-seq or MERFISH. *`full mode`: no restrictions
on number of cell types, recommended for low spatial resolution
technologies such as Visium. \*`multi mode`: finitely many cell types
per pixel, e.g. 3 or 4.

### RCTD results structure

The results of RCTD are located in the `@results` field.

**Full mode results**: `@results$weights`, a data frame of cell type
weights for each pixel for full mode. Weights should subsequently be
normalized using the `normalized_weights <- normalize_weights(weights)`
function. Weights will then add up to one for each pixel, representing
cell type proportions.

**Doublet mode results:** The results of ‘doublet_mode’ are stored in
`@results$results_df`. More specifically, the `results_df` object
contains one column per pixel (barcodes as rownames). Important columns
are: \* `spot_class`, a factor variable representing RCTD’s
classification in doublet mode: “singlet” (1 cell type on pixel),
“doublet_certain” (2 cell types on pixel), “doublet_uncertain” (2 cell
types on pixel, but only confident of 1), “reject” (no prediction given
for pixel). Typically, `reject` pixels should not be used, and
`doublet_uncertain` pixels can only be used for applications that do not
require knowledge of all cell types on a pixel. \* Next, the
`first_type` column gives the first cell type predicted on the bead (for
all spot_class conditions except “reject”). \* The `second_type column`
gives the second cell type predicted on the bead for doublet spot_class
conditions (not a confident prediction for “doublet_uncertain”).

Additionally, `@results$weights_doublet` contains the doublet
proportions for each cell type (`first_type` and `second_type`),
respectively. One can use `get_doublet_weights` to convert the doublet
mode weights to a matrix across all cell types.

**Multi mode results:** results consists of a list of results for each
pixel, which contains `all_weights` (weights from full-mode),
`cell_type_list` (cell types on multi-mode), `conf_list` (which cell
types are confident on multi-mode) and `sub_weights` (proportions of
cell types on multi-mode).

## C-SIDE

### Constructing design matrix / explanatory variables and running C-SIDE

In order to learn cell type-specific differential expression, one must
first define one or multiple axis along which to expect differential
gene expression. These axis are termed *explanatory variables*. Each
explanatory variable is a vector of values, constrained between 0 and 1,
with names matching the pixel names of the `myRCTD` object. For example,
in the C-SIDE vignettes, many examples are provided of using
e.g. spatial position, cell-to-cell interactions, or discrete regions as
explanatory variables.

In the most common case, if a single explanatory variable is present,
C-SIDE can be run using the `run.CSIDE.single` function:

``` r
myRCTD <- run.CSIDE.single(myRCTD, explanatory.variable)
```

If multiple explanatory variables are present, then one can contruct the
design matrix `X` directly. Several functions are provided in order to
aid with design matrix construction including
`build.designmatrix.single`, `build.designmatrix.regions`, and
`build.designmatrix.nonparametric`. For example, for the case where one
desires to test for differential expression across multiple (e.g. four)
regions, one can construct `X` by organizing pixel barcodes into
`region_list`, which is a list of character vectors, where each vector
contains pixel names, or barcodes, for a single region:

``` r
X <- build.designmatrix.regions(myRCTD, region_list)
```

After constructing the design matrix, one can use the general purpose
`run.CSIDE` as follows:

``` r
myRCTD <- run.CSIDE(myRCTD, X, barcodes, cell_types)
```

Here, `barcodes` represents a list of pixel names that should be
included, while `cell_types` is a list of cell types that should be
included in the model.

In addition to using `run.CSIDE`, one can also consider
`run.CSIDE.regions`, which can detect DE across multiple regions, and
`run.CSIDE.nonparametric` for running nonparametric C-SIDE to fit smooth
functions.

Consider also the following options for any of the `run.CSIDE.x` family
of functions: \* `gene_threshold`: (default 5e-5) the minimum expression
of genes to be included in the C-SIDE model. \* `doublet_mode`: (default
TRUE) whether doublet mode or full mode weights are used in C-SIDE. \*
`test_mode`: (default individual) if individual, tests DE coefficients
individually for significant DE. If categorical (e.g. in case of
multiple regions), then tests for differences across categories. \*
`cell_type_threshold`: (default 125): minimum pixel occurrences of each
cell type. We recommend that each cell type that is included occur at
least on 50-100 pixels (see `count_cell_types` or `aggregate_cell_types`
for counting cell type pixels). \* `cell_types_present`: List of other
cell types that could be present in the dataset that could contaminate
the measurements for cell types being analyzed. \* `params_to_test`:
List of indices for which parameters should be tested. \*
`test_genes_sig`: Whether C-SIDE should test genes for significance. \*
`fdr`: False discovery rate for C-SIDE gene testing.

### C-SIDE results structure

C-SIDE results are stored in `myRCTD@de_results`. All gene expression
results are computed in the natural log. The first object of interest
containing C-SIDE results for all genes is
`myRCTD@de_results$gene_fits`, referred to henceforth as `gene_fits`.
This object is itself a list of several vectors and matrices of
interest, including:

-   `gene_fits$mean_val`: A genes by cell types matrix representing the
    C-SIDE point estimate of the differential expression coefficient of
    the explanatory variable. For example, if the explanatory variable
    represents two regions (0 and 1 variable), the `mean_val` represents
    the log-fold-change between regions. For example,
    `mean_val['geneA', 'Neuron'` would represent estimated DE for
    `geneA` in cell type `Neuron`. If multiple explanatory variables are
    present, one should consult the `all_vals` table instead, as
    described below.
-   `gene_fits$all_vals`: All coefficients estimated by the C-SIDE
    model. Dimensions: genes X explanatory variables X cell types. For
    example, consider the case where the design matrix has categorical
    variables for four regions. In this case,
    `all_vals['geneA', 3, 'Neuron']` would represent the estimated
    coefficient (log gene expression) for geneA in cell type Neuron in
    region 3.
-   `con_mat`: A genes by cell types logical matrix representing
    convergence for each gene and for each cell type. For example,
    `con_mat['geneA', 'Neuron'` would represent convergence of the model
    on `geneA` in cell type `Neuron`. It is possible to converge for
    some cell types but not others, which occurs most commonly if one
    cell type is much more lowly expressed.
-   `s_mat`: A genes by coefficients matrix representing the standard
    errors for each coefficient for each gene. We represent reshaping
    the matrix into a three dimensional tensor with
    `s_mat_3d <- get_standard_errors(s_mat)`. Dimensions: genes X
    explanatory variables X cell types. Then,
    e.g. `s_mat_3d['geneA', 3, 'Neuron']` would represent the
    coefficient standard error (log gene expression) for geneA in cell
    type Neuron and the third explanatory variable.
-   `sigma_g`: A vector, across genes, of the estimated standard
    deviation (magnitude) of pixel-specific overdispersion. A higher
    value of `sigma_g` indicates a higher level of noise compared to the
    Poisson distribution.

C-SIDE significant gene results are stored in
`myRCTD@de_results$gene_fits`, which is a list of dataframes for each
cell type. For example the following extracts the significant gene
dataframe for the ‘Neuron’ cell type:

``` r
sig_df_neuron <- myRCTD@de_results$sig_gene_list[['Neuron']]
```

This dataframe has rows for each significant gene. Columns will vary
depending on C-SIDE mode, and one should consult the vignette of each
mode for specific information. In most cases the following columns will
be present:

-   `log_fc`: the estimated differential expression, along the
    explanatory variable of interest, in natural log space.
-   `se`: the standard error of this differential expression estimate.
-   `paramindex_best`: the index of the coefficient that was tested for
    differential expression for this gene. This is relevant if multiple
    explanatory variables need to be distinguished.
-   `Z_score`: the Z-score for a statistical Z-test, if applicable.
-   `p_val`: the p-value for the statistical test of DE for this gene.
-   `conv`: whether C-SIDE converged for this gene (required to achieve
    significance).

### Multiple replicates

RCTD and C-SIDE can be run in batch mode on multiple replicates. This
involves the creation of an `RCTD.replicates` object, which stores
multiple `SpatialRNA` experimental replicates. Then, one can use
`run.RCTD.replicates` and `run.CSIDE.replicates` to run RCTD and C-SIDE,
respectively. This procedure is documented in detail in the
[Population-level RCTD and C-SIDE
vignette](https://raw.githack.com/dmcable/spacexr/master/vignettes/replicates.html).
