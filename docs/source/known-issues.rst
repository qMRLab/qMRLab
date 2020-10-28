Known issues
===============================================================================

OSX
-------------------------------------------------------------------------------
Due to security updates in OSX release 10.15 (macOS Catalina), the `Gatekeeper`
may flag `*.mex*` files in qMRLab as unsafe and quarantine them. In this case, 
you won't be able to start qMRLab and the following error will appear: 

.. warning::
    **filename.mexmaci64 cannot be opened because the developer cannot be verified.**
    macOS cannot verify that this app is free from malware.

To lift the quarantine and to add Gatekeeper exceptions for the qMRLab's `mex` files,
start a terminal and run the following::

    sudo xattr -r -d com.apple.quarantine /full/path/to/qMRLab
    sudo find /full/path/to/qMRLab -name \*.mexmaci64 -exec spctl --add {} \;

Please open `a new issue <https://github.com/qMRLab/qMRLab/issues/new/choose>`_ if this
solution did not work for you. 