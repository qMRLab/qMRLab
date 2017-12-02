#!/usr/bin/env python

import os
import sys
import shutil
import xml.etree.ElementTree
import io
import copy
import embed_html

sys.path.append("embed_html.py")
sys.path.insert(0, os.path.abspath('../..'))

#Model class
class Model(object):
	"""Model class with the name"""
	def __init__(self, file, name, category, demo):
		super(Model, self).__init__()
		#File name
		self._file = file
		#Complete name for doc
		self._name = name
		#Categorization
		self._category = category
		#TRUE if there's a demo html file
		self._demo = demo

category_list = []
models = []
for root, dirs, files in os.walk('../Models'):
	#Check the models that are there
	for name in files:
		if name.endswith('.m'):
			#Get the file name
			name_pos = name.find(".m")
			cfile = name[:name_pos]

			#Get the file category (in wich folder it's located)
			#Get the index to split the folder path
			root_pos = root.find("Models")
			skip_pos = len("Models")
			end_pos = root.find("\\", root_pos + skip_pos+1)
			#Get the category if the folder is the last element in the path
			if end_pos == -1:
				ccat = root[root_pos + skip_pos + 1:]
			#Get the category if the folder is the not the last element in the path
			else:
				ccat = root[root_pos + skip_pos + 1:root.find("\\", root_pos + skip_pos+1)]
			used = False

			#Build a category list to build the toctree later on
			for cat in category_list:
				if cat == ccat:
					used = True
			if not used:
				category_list.append(ccat)

			#Get the complete name 
			cname = ""
			#Open the model matlab file
			with io.open(os.path.join(root,name), 'rb') as fr:
				found = False
				#Go throught the file until the name is found
				while not found:
					text = fr.read()
					line_lst = text.split('\n')
					cname = [l for l in line_lst if '%' in l][0].split('%')[1]
					cname = cname.strip()
					found = True
					print cname

			#Get the information if there is a demo folder with the batch_example
			cdemo = False
			#Check for a .m file in demo
			for root_s, dirs_s, files_s in os.walk('../Data'):
				for name_s in files_s:
					#Remove the _batch part in the file name
					name_pos = name_s.find("_batch")
					#Check if the file name ends with html and if it's the same model
					if name_s.endswith(".html") and cfile.lower() == name_s[:name_pos].lower():
						#There is a demo folder
						cdemo = True
						#Set the destination and the source location for the .rst fils
						dst = './source/'+ cfile +'_batch.rst'
						src = '../Data/' + cfile + '_demo/html/'+cfile+'_batch.html'
						#Copy the html file into a rst file in the correct location
						os.system("python embed_html.py "+dst+" "+src+" \""+cname+"\"")
					#Copy the png files
					elif name_s.endswith(".png"):
						#Save the path of the ".png" file 
						fn = os.path.join(root_s, name_s)
						#Copy the ".png" file to the new location
						shutil.copy(fn, "./source/_static")

			#Add the model to the list
			model_add = Model(
				cfile,
				cname,
				ccat,
				cdemo)
			models.append(model_add)

#Open a dummy documentation file and the documentation file to write the totree
with io.open("./source/documentation.rst", "r") as fr:
	with io.open("./source/documentationTemp.rst", "w") as fw:
		in_Models = False
		i = -1
		#Go througth each line
		for line in fr:
			#Check if you're in the correct location of the file
			if line == "Methods available\n":
				i = 1
				in_Models = True
				fw.write(line)
				fw.write(u'-------------------------------------------------------------------------------\n')
				fw.write(u"\n")
			#Check if the toctree is finished
			if line == "Getting started\n":
				in_Models = False
			#Write the toctree
			if i == 0 and in_Models:
				#Write for each category in the list of found categories
				for cat in category_list:
					fw.write(cat + u"\n")
					fw.write(u"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")
					for element in models:
						#If there is a demo, add the link
						if element._category == cat and element._demo:
							fw.write(u".. toctree::\n")
							fw.write(u"\t:maxdepth: 1\n")
							fw.write(u"\n")
							fw.write(u"\t" + element._file.decode('utf8') + u"_batch\n")
							fw.write(u"\n")
						#If there is no demo, add a description without link
						elif element._category == cat and not element._demo:
							fw.write('* '+element._name.decode('utf8'))
							fw.write(u"\n\n")
			i = i - 1
			#Write every line exept the old toctree
			if not in_Models:
				fw.write(line)

#Close the files
fr.close()
fw.close()

#Open the previous files in reverse role and copy the new one in the old file
with io.open("./source/documentationTemp.rst", "r") as fr:
	with io.open("./source/documentation.rst", "w") as fw:
		for line in fr:
			fw.write(line)

#Close the files and remove the temporary file
fr.close()
fw.close()
os.remove("./source/documentationTemp.rst")
