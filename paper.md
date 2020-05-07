---
title: 'qMRLab: Quantitative MRI Analysis, under one umbrella'
tags:
  - Matlab
  - Octave
  - quantitative magnetic resonance imaging
  - mri
  - neuroimaging
authors:
  - name: Agah Karakuzu
    orcid: 0000-0001-7283-271X
    affiliation: "1, 4"
  - name: Mathieu Boudreau
    orcid: 0000-0002-7726-4456
    affiliation: "1, 4"
  - name: Tanguy Duval
    orcid: 0000-0002-1228-5192
    affiliation: 1
  - name: Tommy Boshkovski
    orcid: 0000-0002-5243-5204
    affiliation: 1
  - name: Ilana R. Leppert
    affiliation: 2
  - name: G. Bruce Pike
    orcid: 0000-0001-8924-683X
    affiliation: "2, 5"
  - name: Julien Cohen-Adad
    orcid: 0000-0003-3662-9532
    affiliation: "1, 3"
  - name: Nikola Stikov
    orcid: 0000-0002-8480-5230
    affiliation: "1, 4"
affiliations:
 - name: NeuroPoly Lab, Institute of Biomedical Engineering, Polytechnique Montreal, Montreal, Canada
   index: 1
 - name: McConnell Brain Imaging Center, Montreal Neurological Institute, McGill University, Montreal, Canada
   index: 2
 - name: Functional Neuroimaging Unit, CRIUGM, University of Montreal, Montreal, Canada
   index: 3
 - name: Montreal Heart Institute, University of Montréal, Montréal, Canada
   index: 4
 - name: Departments of Radiology and Clinical Neuroscience,  Hotchkiss Brain Institute, University of Calgary, Calgary, Canada
   index: 5
date: 02 March 2020
bibliography: paper.bib
---

# Summary

Magnetic resonance imaging (MRI) has revolutionized the way we look at the human body. However, conventional MR scanners are not measurement devices. They produce digital images represented by “shades of grey”, and the intensity of the shades depends on the way the images are acquired. This is why it is difficult to compare images acquired at different clinical sites, limiting the diagnostic, prognostic, and scientific potential of the technology.

Quantitative MRI (qMRI) aims to overcome this problem by assigning units to MR images, ensuring that the values represent a measurable quantity that can be reproduced within and across sites. While the vision for quantitative MRI is to overcome site-dependent variations, this is still a challenge due to variability in the hardware and software used by MR vendors to produce quantitative MRI maps.

Although qMRI has yet to enter mainstream clinical use, imaging scientists see great promise in the technique's potential to characterize tissue microstructure. However, most qMRI tools for fundamental research are developed in-house and are difficult to port across sites, which in turn hampers their standardization, reproducibility, and widespread adoption.

To tackle this problem, we developed qMRLab, an open-source software package that provides a wide selection of qMRI methods for data fitting, simulation and protocol optimization \autoref{fig:header}. It not only brings qMRI under one umbrella, but also facilitates its use through documentation that features online executable notebooks, a user friendly graphical user interface (GUI), interactive tutorials and blog posts.

![qMRLab is an open-source software for quantitative MRI analysis It provide a myriad of methods to characterize microstructural tissue properties, from relaxometry to magnetization transfer.\label{fig:header}](https://github.com/qMRLab/qMRLab/raw/master/docs/logo/header_new.png)

MATLAB is the native development language of qMRLab, primarily because it is by far the most common choice among MRI methods developers. However, we have made a strong effort to lower licensing and accessibility barriers by supporting Octave compatibility and Docker containerization.

qMRLab started as a spin-off project of qMTLab [@cabana:2015]. In the meantime, a few other open-source software packages were developed, addressing  the lack of qMRI consistency  from different angles. QUIT [@wood:2018] implemented an array of qMRI methods in C++, which is highly favorable as an on-site solution because of its speed. The hMRI toolbox [@tabelow:2019] was developed as an SPM [@ashburner:1994] module that expands on the multi-parametric mapping method [@weiskopf:2008]. Other tools such as mrQ [@mezer:2016] and QMAP [@samsonov:2011] are also primarily designed for brain imaging. Yet, brain imaging is not the only qMRI area slowed down by lack of consistency. Recently we published a preprint demonstrating notable disagreements between cardiac qMRI methods [@hafyane:2018]. Open-source software can go a long way in explaining these discrepancies, and the cardiac imaging community was recently introduced to TOMATO [@werys:2020], an open C++ framework for parametric cardiac MRI.

As open-source practices in the realm of qMRI become more popular, the need for effective communication of these tools also increases. This is important not only because we need consistency and transparency in the implementations, but also because non-specialist qMRI users would benefit from better understanding of the methodology. To this end, we envision qMRLab as a powerful tool with which users can easily interact with various techniques, perform simulations, design their experiments and fit their data. We reinforce this vision through our web portal (https://qmrlab.org) that includes interactive tutorials, blog posts and Jupyter Notebooks running on BinderHub, all tailored to a wide range of qMRI methods. The qMRLab portal is open for community contributions.

Currently, qMRLab is used by dozens of research labs around the world, mostly, but not limited to, application in brain and spinal cord imaging. A list of published studies using qMRLab is available on our GitHub repository.

While closed solutions may be sufficient for qualitative MRI (shades of grey lack standardized units), quantitative MRI will not realize its potential if we cannot peek inside the black box that generates the numbers. With qMRLab we want to open the black boxes developed in-house and reach a critical mass of users across all MR vendor platforms, while also encouraging developers to contribute to a central repository where all features and bugs are in the open. We hope that this concept will level the field for MR quantification and open the door to vendor-neutrality. We've been sitting in our MR cathedrals long enough. It is now time to join the MR bazaar [@raymond:1999]!

# Acknowledgements

This research was undertaken thanks, in part, to funding from the Canada First Research Excellence Fund through the TransMedTech Institute. The work is also funded in part by the Montreal Heart Institute Foundation, Canadian Open Neuroscience Platform (Brain Canada PSG), Quebec Bio-imaging Network (NS, 8436-0501 and JCA, 5886, 35450), Natural Sciences and Engineering Research Council of Canada (NS, 2016-06774 and JCA, RGPIN-2019-07244), Fonds de Recherche du Québec (JCA, 2015-PR-182754), Fonds de Recherche du Québec - Santé (NS, FRSQ-36759, FRSQ-35250 and JCA, 28826), Canadian Institute of Health Research (JCA, FDN-143263 and GBP, FDN-332796), Canada Research Chair in Quantitative Magnetic Resonance Imaging (950-230815), CAIP Chair in Health Brain Aging, Courtois NeuroMod project and International Society for Magnetic Resonance in Medicine (ISMRM Research Exchange Grant).

# References
