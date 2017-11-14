 "MPPCA": 4d image denoising and noise map estimation by exploiting  data redundancy in the PCA domain using universal properties of the eigenspectrum of
     random covariance matrices, i.e. Marchenko Pastur distribution
    
      [Signal, Sigma] = MPdenoising(data, mask, kernel, sampling)
           output:
               - Signal: [x, y, z, M] denoised data matrix
               - Sigma: [x, y, z] noise map
           input:
               - data: [x, y, z, M] data matrix
               - mask:   (optional)  region-of-interest [boolean]
               - kernel: (optional)  window size, typically in order of [5 x 5 x 5]
               - sampling: 
                        1. full: sliding window (default for noise map estimation, i.e. [Signal, Sigma] = MPdenoising(...) )
                        2. fast: block processing (default for denoising, i.e. [Signal] = MPdenoising(...))
     
      Authors: Jelle Veraart (jelle.veraart@nyumc.org)
     Copyright (c) 2016 New York Universit and University of Antwerp
           
          Permission is hereby granted, free of charge, to any non-commercial entity
          ('Recipient') obtaining a copy of this software and associated
          documentation files (the 'Software'), to the Software solely for
          non-commercial research, including the rights to use, copy and modify the
          Software, subject to the following conditions: 
           
            1. The above copyright notice and this permission notice shall be
          included by Recipient in all copies or substantial portions of the
          Software. 
           
            2. THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
          EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIESOF
          MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
          NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BELIABLE FOR ANY CLAIM,
          DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
          OTHERWISE, ARISING FROM, OUT OF ORIN CONNECTION WITH THE SOFTWARE OR THE
          USE OR OTHER DEALINGS IN THE SOFTWARE. 
           
            3. In no event shall NYU be liable for direct, indirect, special,
          incidental or consequential damages in connection with the Software.
          Recipient will defend, indemnify and hold NYU harmless from any claims or
          liability resulting from the use of the Software by recipient. 
           
          4. Neither anything contained herein nor the delivery of the Software to
          recipient shall be deemed to grant the Recipient any right or licenses
           under any patents or patent application owned by NYU. 
           
            5. The Software may only be used for non-commercial research and may not
          be used for clinical care. 
           
            6. Any publication by Recipient of research involving the Software shall
          cite the references listed below.
     
     REFERENCES
          Veraart, J.; Fieremans, E. & Novikov, D.S. Diffusion MRI noise mapping
          using random matrix theory Magn. Res. Med., 2016, early view, doi:
          10.1002/mrm.26059
