# AMICO

Implementation of the linear framework for Accelerated Microstructure Imaging via Convex Optimization (AMICO) described here:

> **Accelerated Microstructure Imaging via Convex Optimization (AMICO) from diffusion MRI data**  
> *Alessandro Daducci, Erick Canales-Rodriguez, Hui Zhang, Tim Dyrby, Daniel Alexander, Jean-Philippe Thiran*  
> NeuroImage 105, pp. 32-44 (2015)

## Code implementation

This is the first/original version implementation of the AMICO framework and is written in MATLAB. **THIS CODE IS NO LONGER MAINTAINED**.

NB: the official version of AMICO is written in **Python** can be found [`here`](https://github.com/daducci/AMICO).

# Installation

## Download and install external software

- **NODDI MATLAB toolbox**. [Download](http://mig.cs.ucl.ac.uk/index.php?n=Download.NODDI) the software and follow the instructions provided [here](http://mig.cs.ucl.ac.uk/index.php?n=Tutorial.NODDImatlab) to install it.  

- **CAMINO toolkit**. [Download](http://cmic.cs.ucl.ac.uk/camino//index.php?n=Main.Download) the software and follow the instructions provided [here](http://cmic.cs.ucl.ac.uk/camino//index.php?n=Main.Installation) to install it.  

- **SPArse Modeling Software (SPAMS)**. [Download](http://spams-devel.gforge.inria.fr/downloads.html) the software and follow the instructions provided [here](http://spams-devel.gforge.inria.fr/doc/html/doc_spams003.html) to install it.  

## Setup paths/variables in MATLAB

Add the folder containing the source code of AMICO to your `MATLAB PATH`.

Copy the file `AMICO_Setup.txt` and rename it to `AMICO_Setup.m`. Modify its content to set the paths to your specific needs, as follows:

- `AMICO_code_path` : path to the folder containing the *MATLAB source code* of AMICO (this repository). E.g. `/home/user/AMICO/code/matlab`.

- `NODDI_path` : path to the folder containing the *source code* of the NODDI toolbox (in case you want to use NODDI, not needed for ActiveAx). E.g. `/home/user/NODDI_toolbox_v0.9`.

- `CAMINO_path` : path to the `bin` folder containing the *executables* of the Camino toolkit (in case you want to use ActiveAx, not needed for NODDI). E.g. `/home/user/camino/bin`.

- `SPAMS_path` : path to the folder containing the *source code* of the SPAMS Library. E.g. `/home/user/spams`.

- `AMICO_data_path` : path to the folder where you store all your datasets. E.g. `/home/user/AMICO/data`. Then, the software assumes the folder structure is the following:

    ```
    ├── data
        ├── Study_01                 --> all subjects acquired with protocol "Study_01"
            ├── Subject_01
            ├── Subject_02
            ├── ...
        ├── Study_02                 --> all subjects acquired with protocol "Study_02"
            ├── Subject_01
            ├── Subject_02
            ├── ...
        ├── ...
    ```
  This way, the kernels need to be computed only *once per each study*, i.e. same protocol (number of shells, b-values etc), and subsequently adapted to each subject (specific gradient directions) very efficiently.


# Getting started

Tutorials/demos are provided in the folder [`doc/demos/`](doc/demos/) to help you get started with the AMICO framework.
