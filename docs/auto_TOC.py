#!/usr/bin/env python

import os
import sys
import shutil
import xml.etree.ElementTree
import io
import copy
import embed_html
sys.path.insert(0, os.path.abspath('../..'))

class Model(object):
	"""Model class with the name"""
	def __init__(self, file, name, category, demo):
		super(Model, self).__init__()
		self._file = file
		self._name = name
		self._category = category
		self._demo = demo

category_list = []
models = []

for root, dirs, files in os.walk('../Models'):
	#Check the models that are there
	for name in files:
		name_pos = name.find(".m")
		cfile = name[:name_pos]

		root_pos = root.find("Models")
		skip_pos = len("Models")
		end_pos = root.find("\\", root_pos + skip_pos+1)
		if end_pos == -1:
			ccat = root[root_pos + skip_pos + 1:]
		else:
			ccat = root[root_pos + skip_pos + 1:root.find("\\", root_pos + skip_pos+1)]
		used = False
		for cat in category_list:
			if cat == ccat:
				used = True
		if not used:
			category_list.append(ccat)
		cname = ""
		with io.open(os.path.join(root,name), 'r') as fr:
			found = False
			while not found:
				line = fr.readline()
				if line.startswith("%"):
					cname = line[1:].lstrip()
					found = True

		cdemo = False
		#Check for a .m file in demo
		for root_s, dirs_s, files_s in os.walk('../Data'):
			for name_s in files_s:
				name_pos = name_s.find("_batch")
				if name_s.endswith(".html") and cfile == name_s[:name_pos]:
					cdemo = True
					dst = './source/'+ cfile +'_batch.rst'
					src = '../Data/' + cfile + '_demo/html/'+cfile+'_batch.html'
					MyHTMLParser(dst,src,cname)#################################################################
				elif name_s.endswith(".png"):
					#Save the path of the ".png" file 
					fn = os.path.join(root_s, name_s)
					#Copy the ".png" file to the new location
					shutil.copy(fn, "./source/_static")

		model_add = Model(
			cfile,
			cname,
			ccat,
			cdemo)
		models.append(model_add)

with io.open("./source/documentation.rst", "r") as fr:
	with io.open("./source/documentationTemp.rst", "w") as fw:
		in_Models = False
		i = -1
		for line in fr:
			if line == "Methods available\n":
				i = 3
				in_Models = True
				fw.write(line)
				fw.write(u'-------------------------------------------------------------------------------\n')
				fw.write(u"\n")
			if line == "Getting started\n":
				in_Models = False
			if i == 0 and in_Models:
				for cat in category_list:
					fw.write(cat + u"\n")
					fw.write(u"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")
					for element in models:
						if element._category == cat and element._demo:
							fw.write(u".. toctree::\n")
							fw.write(u"\t:maxdepth: 1\n")
							fw.write(u"\n")
							fw.write(u"\t" + element._file + u"_batch\n")
							fw.write(u"\n")
						elif element._category == cat and not element._demo:
							fw.write(element._name)
							fw.write(u"\n")
			i = i - 1
			if not in_Models:
				fw.write(line)
fr.close()
fw.close()
with io.open("./source/documentationTemp.rst", "r") as fr:
	with io.open("./source/documentation.rst", "w") as fw:
		for line in fr:
			fw.write(line)
fr.close()
fw.close()
os.remove("./source/documentationTemp.rst")
