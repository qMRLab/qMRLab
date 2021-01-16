qMRFlow
====================================

About
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. image:: https://github.com/qMRLab/qMRFlow/raw/master/assets/qmrflow_small.png?raw=true
  :width: 400

qMRFlow is a collection of container-mediated, data-driven, transparent and platform-agnostic qMRI workflows written in `Nextflow <https://www.nextflow.io/>`_.

.. image:: https://img.shields.io/badge/GitHub-qMRFlow-ff0000.svg
 :target: https://github.com/qMRLab/qMRFlow

Benefits
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- qMRLab implements a myriad of qMRI methods, however does not provide pre-processing solutions such as volume alignment or skull stripping. qMRFlow enables the easy use of virtually any pre-processing software with qMRLab, as the process logic and descriptions are detached from workflow orchestration.

.. image:: https://github.com/qMRLab/qMRFlow/blob/master/assets/ismrm_tools_workflow.png?raw=true
  :width: 800

- qMRFlow pipelines run on `BIDS <https://bids-specification.readthedocs.io/en/stable/>`_ formatted data, highly convenient for multi-subject processing: 

.. image:: https://media.springernature.com/m685/springer-static/image/art%3A10.1038%2Fsdata.2016.44/MediaObjects/41597_2016_Article_BFsdata201644_Fig1_HTML.jpg
  :width: 800


To see the latest BIDS developments on describing qMRI data, you can visit `BEP001 GitHub repository <https://github.com/orgs/bids-bep001/dashboard>`_.

- Quantitative maps created by qMRFlow are accompanied by sidecar json files containing provenance metadata about the executed qMRI process: 

.. image:: https://github.com/qMRLab/qMRFlow/blob/master/assets/output_formatting.png?raw=true
  :width: 800

- Nextflow data-driven workflow engine provides comprehensive reports after a pipeline is run:

.. image:: https://github.com/qMRLab/qMRFlow/blob/master/assets/workflow_report.png?raw=true
  :width: 800

- In case that the workflow is interrupted for any reason, pipeline execution can be resumed from where it left off.

Use qMRFlow with Docker 🐳
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
If you have Docker installed on your computer, getting started with qMRFlow is 
a few steps away. 

1. Install Nextflow as described in `here <https://www.nextflow.io/>`_.
2. Pull Docker images listed by a qMRFlow pipeline. For example, to run MTsat workflow in containers, following images must be pulled::

    docker pull qmrlab/minimal:v2.3.1
    docker pull qmrlab/antsfsl:latest
3. Run the pipeline as described in the `Usage` section of the desired qMRFlow pipeline documentation.

Use qMRFlow locally 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
We highly suggest using qMRFlow workflows in containers. However, if you don't 
have Docker installed, you can still use them by installing dependencies locally.

1. Ensure that all the dependencies listed by the `Local installation requirements` section of the desired qMRFlow pipeline documentation are met.
2. Install qMRLab 
3. Run the pipeline as described in the `Usage` section of the desired qMRFlow pipeline documentation.