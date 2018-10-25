# imtool3D
This is an image viewer designed to view a 3D stack of image slices. For example, if you load into matlab a DICOM series of CT images, you can visualize the images easily using this tool. It lets you scroll through slices, adjust the window and level, make ROI measurements, and export images into standard image formats (e.g., .png, .jpg, or .tif). This tool is written using the object-oriented features of matlab. This means that you can treat the tool like any graphics object and it can easily be embedded into any figure. So if you're designing a GUI in which you need the user to visualize and scroll through image slices, you don't need to write all the code for that! Its already done in this tool! Just create an imtool3D object and put it in your GUI figure.

imtool3D is used heavily by several other RAI labs projects:
* [imquest](https://gitlab.oit.duke.edu/railabs/SameiResearchGroup/imquest)
* [lesionTool](https://gitlab.oit.duke.edu/railabs/SameiResearchGroup/lesionTool)

# Dependencies
* Matlab's image processing toolbox
* Matlab's Statistics and Machine Learning toolbox

# Authors
Justin Solomon
Tanguy Duval

# Original release
https://fr.mathworks.com/matlabcentral/fileexchange/40753-imtool3d