import math
import networkx as nx
import numpy as np

from scipy.sparse.linalg import eigsh
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from sklearn.cluster import KMeans
from sklearn.mixture import GaussianMixture

###############################################################################
## #####  rpy2 stuff  ######
# import rpy2's package module
import rpy2.robjects.packages as rpackages
import rpy2.robjects as robjects
import rpy2.robjects.numpy2ri
rpy2.robjects.numpy2ri.activate()

# Comment out these three lines to see warning/error messages
import warnings
from rpy2.rinterface import RRuntimeWarning
warnings.filterwarnings("ignore", category=RRuntimeWarning)

# R package names
packnames = ('mclust')
utils = rpackages.importr('utils')
base = rpackages.importr('base')
utils.chooseCRANmirror(ind=1) # select the first mirror in the list
from rpy2.robjects.vectors import StrVector
utils.install_packages(StrVector(packnames))

mclust = rpackages.importr('mclust')
###############################################################################


def cluster_km(E):
	return KMeans(n_clusters=2, random_state=0).fit(E).labels_

## renamed the original definition
def cluster_gmm_original(E):
	tmp =  GaussianMixture(n_components=2).fit(E).predict(E)
	return tmp

###############################################################################
## new def for R's mclust
def cluster_gmm(E):
	nr,nc = E.shape
	Er = robjects.r.matrix(E, nrow=nr, ncol=nc)
	robjects.r.assign("E", Er)
	mc = mclust.Mclust(Er, G=2, verbose=0)
	Y = mc.rx2("classification")

	return np.array(Y, dtype=np.uint8) - 1
###############################################################################


def eval_cluster(c,b):
	# this should be parametric, but I'm lazy.
	# find the smallest cluster (out of two)
	C = set(i for i in range(len(c)) if c[i] == 0)

	for j in range(1,max(c)+1):
		Cp = set(i for i in range(len(c)) if c[i] == j)
		if len(Cp) < len(C):
			C = Cp
		Bs = [ set(i for i in range(len(c)) if b[i] == j) for j in range(max(b)+1)]
	return [len(C.intersection(B)) for B in Bs]

def cluster_results(E,b):
	return eval_cluster(cluster_gmm(E), b)

def experiment(P):
	while 1:
		G = nx.generators.stochastic_block_model([int(1000*x) for x in pi],P)
		if nx.is_connected(G):
			break

	B = nx.get_node_attributes(G,'block')
	b = np.zeros(len(B),dtype='int')
	for x in range(len(b)):
		b[x] = B[x]

	A = nx.adjacency_matrix(G).astype('d')
	evals_large, evecs_large = eigsh(A, 2, which='LM')
	ASE = np.dot(evecs_large, np.diag(np.sqrt(evals_large)))

	rval = cluster_results(ASE,b)

	L = -nx.normalized_laplacian_matrix(G)
	for i in range(len(b)):
		L[i,i] += 1.0
	evals_large, evecs_large = eigsh(L, 2, which='LM')
	LSE = np.dot(evecs_large, np.diag(np.sqrt(evals_large)))

	rval.extend(cluster_results(LSE,b))
	return rval

# P1 = np.array(
# 	[[0.009, 0.019, 0.000, 0.002],
# 	[0.019, 0.077, 0.002, 0.013],
# 	[0.000, 0.002, 0.009, 0.019],
# 	[0.002, 0.013, 0.019, 0.076]])

P1 = np.array(
	[[0.018932108, 0.042869173, 0.002084243, 0.008436194],
	[0.042869173, 0.112538688, 0.009629583, 0.040333219],
	[0.002084243, 0.009629583, 0.019360040, 0.044269707],
	[0.008436194, 0.040333219, 0.044269707, 0.115217630	]])

pi = np.array([0.28,0.22,0.28,0.22])

results = [ experiment(P1) for t in range(10) ]
print(np.array(results))
