# Wavelet Transform

# Description

The wavelet transform can be seen as an alternative to the FFT.

Essentially it's a convolution of a small wave or 'wavelet'.

A wavelet is created from which is integral of close together cosine waves, and
ends up looking like mini-version of the center freq.

Typically, the shape of the wavelet is the same for each of ranges of interest,
just scaled.

## More Wavelet Details


### Wavelets Retain Phase Data

With wavelet's one sees not just the intensity of frequency, but whether high or low at that point in time.

This is very interesting to monitoring and extrapolating patterns in the data.

### Wavelets Increase Temporal Resolution vs FFT

Unlike the fft (which uses same time scale for multiple frequencies), each
frequency range has very high temporal localization.

This also means different resolution between different frequencies, higher frequencies
will have higher temporal resolution.

Will be better or at par with temporal resolution than the fourier frequency transform.

### Implementation

Under the hood, effectively, each wavelet is a FIR notch pass filter.
