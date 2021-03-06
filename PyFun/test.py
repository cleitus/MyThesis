#!/usr/bin/python

import numpy, os, glob, pylab
from scipy.optimize import fmin
import matplotlib.pyplot as plt
from shapely.geometry.polygon import  LinearRing, Polygon, LineString
from collections import *
#from statistics import *

filename1 = "2d_tirant_micro"
wd1 = "/home/christian/Documents/FIDES/FIDES_Resultats_calculs/2D/" + filename1
filename2 = "3d_tirant_macro" #model
wd2 = "/home/christian/Documents/FIDES/FIDES_Resultats_calculs/3D/" + filename2
wd2 = wd2 + "/16"

colonne_1 = 1
colonne_2 = 4

##################################

def area(p):
	return 0.5*abs(sum(x0*y1 - x1*y0 for ((x0, y0), (x1,y1)) in segments(p)))

def segments(p):
	return zip(p, p[1:]+[p[0]])

os.chdir(wd1)
Files1 = filename1 + "*"
n1 = len(glob.glob(Files1))

os.chdir(wd2)
Files2 = filename2 + "*"
n2 = len(glob.glob(Files2))

f = []

os.chdir(wd1)
for fichier1 in glob.glob(Files1):
	os.chdir(wd1)
	datalist = numpy.loadtxt(fichier1)
	n = len(datalist[0])
	data = []
	dict_Y = {}
	for i in range(n):
		data.append(datalist[:,i])
	X = [x for x in data[colonne_1 - 1] if str(x)!="nan"]
	Y = [y for y in data[colonne_2 - 1] if str(y)!="nan"]
	Y = [y/(max(Y)/max(X)) for y in Y]
	if colonne_1 == "4":
		XX = [ float('%.2f' % elem) for elem in X ]
	else:
		XX = [ float('%.8f' % elem) for elem in X ]
	for i in range(len(XX)):
		dict_Y[XX[i]] = []
		dict_Y[XX[i]].append(Y[i])
	for i in dict_Y:
		dict_Y[i] = sum(dict_Y[i])/len(dict_Y[i])
	mod_Y1 = OrderedDict(sorted(dict_Y.items(), key=lambda t: t[0]))
	xy1 = list(zip(mod_Y1.keys(), mod_Y1.values()))
	os.chdir(wd2)
	for fichier2 in glob.glob(Files2):
		datalist = numpy.loadtxt(fichier2)
		n = len(datalist[0])
		data = []
		dict_Y = {}
		for i in range(n):
			data.append(datalist[:,i])
		X = [x for x in data[colonne_1 - 1] if str(x)!="nan"]
		Y = [y for y in data[colonne_2 - 1] if str(y)!="nan"]
		Y = [y/(max(Y)/max(X)) for y in Y]
		if colonne_1 == "4":
			XX = [ float('%.2f' % elem) for elem in X ]
		else:
			XX = [ float('%.8f' % elem) for elem in X ]
		for i in range(len(XX)):
			dict_Y[XX[i]] = []
			dict_Y[XX[i]].append(Y[i])
		for i in dict_Y:
			dict_Y[i] = sum(dict_Y[i])/len(dict_Y[i])
		mod_Y2 = OrderedDict(sorted(dict_Y.items(), key=lambda t: t[0]))
		xy2 = list(zip(mod_Y2.keys(), mod_Y2.values()))
		
		poly = xy1 + xy2[::-1]
		lr = LinearRing(poly)
		if lr.is_valid:
			A = Polygon(lr).area
		else:
			A = Polygon(poly).buffer(0).area + Polygon(poly[::-1]).buffer(0).area
		
		f.append(A*10**8)
		print A*10**8
	os.chdir(wd1)

print "optimisation methode yields: "
print "mean :", sum(f)/len(f), "\n", "std  :", numpy.std(f)

F = []

for i in range(min(n1, n2)):
	mini = min(f)
	Id = f.index(mini)
	for j in range((Id-Id%n2),(Id-Id%n2+n2)):
		f[j] = float("inf")
	for j in range((0+Id%n2),n1*n2,n2):
		f[j] = float("inf")
	F.append(mini)

print "minimization methode yields: ", F

os.chdir("/home/christian/Documents/MyThesis/PyFun")
print "mean :", sum(F)/len(F), "\n", "std  :", numpy.std(F)


