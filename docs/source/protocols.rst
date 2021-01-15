Protocols
===============================================================================

This section addresses some frequently asked questions regarding acquisition 
protocols and how to set them in qMRLab. 

mp2rage
-------------------------------------------------------------------------------

You can visit `our MP2RAGE blog post <https://qmrlab.org/2019/04/08/T1-mapping-mp2rage.html>`_ to find out about
the basics of the ``MP2RAGE`` method.

``NumberOfShots``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This section of the ``Protocol`` panel expects two ``NumberOfShots`` values: ``Pre`` and ``Post``.

In the `original implementation <https://github.com/JosePMarques/MP2RAGE-related-scripts>`_, the
``NumberOfShots`` is referred as ``nZSlices``, and ``before/after`` designates the number of segments
before and after the center of k-space.

To calculate these values, you need to know the values of ``Slices Per Slab`` **(NSlices)** and ``Slice Partial Fourier``
**(PF)** parameters. To calculate ``Pre`` and ``Post``::

Pre
  Formula::

        Pre  = NSlices(PF - 0.5)

Post
  Formula::

        Post = NSlices/2


``Repetition Times``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Inversion (Inv)
  ``RepetitionTime`` (in ``DICOM``) between two inversion pulses in seconds. In the (Siemens) 
  ``PDF`` it is described as ``TR`` under the **Contrast - Common** section. In **BIDS**, this 
  corresponds to the ``RepetitionTimePreparation`` metadata field. Typically between 3 - 6 seconds.

Excitation (Inv)
  The repetition time between two excitation pulses in each GRE readout block. In the (Siemens) 
  ``PDF`` it is described as ``Echo spacing`` (usually) under the **Sequence - Part 1** section.
  In **BIDS**, this corresponds to the ``RepetitionTimeExcitation`` metadata field. Typically around
  0.006 - 0.008 seconds.

.. warning::
    Some parameters are not included in the ``DICOM`` header by Siemens, such as the
    ``RepetitionTimeExcitation``. Nonetheless, can be accessed in the protocols exported as ``PDF``. 

``Inversion Times``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Inversion times belonging to each GRE readout block. In the (Siemens) protocol ``PDF``, these 
values can be found under the **Contrast - Common** section with the names of ``TI 1`` and ``TI 2``. 

``Flip Angles``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Excitation flip angles in each GRE readout block. In the (Siemens) protocol ``PDF``, these 
values can be found under the **Contrast - Common** section with the names of ``Flip angle 1`` 
and ``Flip angle 2``.