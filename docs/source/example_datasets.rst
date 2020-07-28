Example datasets
=========================================

.. figure:: https://www.library.ucla.edu/sites/default/files/media/osf-logo-black.original.png
   :scale: 30%
   :width: 400px

Every qMRLab model comes with an example dataset stored in our `public OSF repository <https://osf.io/tmdfu/>`_.
These datasets can be directly downloaded from the OSF, or using qMRLab's 
interfaces.

Download example datasets via GUI
------------------------------------

After selecting a model from the dropdown menu, you can use *Download Data* (blue) button located at the upper right corner of the data panel to download the respective dataset:

.. figure:: _static/gui_download.png
   :scale: 100 %

You will be prompted for a directory where the example dataset will be saved. After the dataset has been downloaded, qMRLab will 
automatically set *Path data* to the download directory and load the input files. *Required* input labels are displayed in bold (e.g., `VFAData`), whereas the labels of the *Optional* inputs are in faded color (e.g., `B1map` and `Mask`). You can get more information about the input fields by clicking question mark buttons next to the input labels.

:: 

  Please note that such auto-loading takes effect only if the name of the images (e.g. VFAData.nii.gz) in the Path data directory are identical with that of the data fields (e.g., VFAData) listed in the data panel.


Download example datasets via CLI
------------------------------------
