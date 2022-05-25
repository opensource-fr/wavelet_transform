import numpy as np
import sys
import math


class CWT_FIR:

    """Creates a FIR with discrete values for the wavelet array. Defaults are for the Ricker Wavelet type."""

    def __init__(
        self,
        bits_per_elem=8,
        elem_ratio=0.577472,
        base_freq=1,
        base_num_elem=3,
        wavelet_order=1,
    ):
        """Defaults are set to Ricker Wavelet type, actual values are
        initialized based off of initial values in order to keep proper ratios
        between wavelet orders.

        Args:
            bits_per_elem (int): number of bits per fir element (e.g. 8 bits)
            elem_ratio (float): 1/freq_ratio also 1/base_num_elem ratio
            base_freq (int): frequency of smallest or initial fir
            base_num_elem (int): number of taps in base fir
            wavelet_order (int): this is the "nth" order of the wavelet array, starts at "0" for base
        """

        self._bits_per_elem = bits_per_elem
        self._elem_ratio = elem_ratio
        self._base_num_elem = base_num_elem
        self._base_freq = base_freq
        self._wavelet_order = wavelet_order
        self._num_elem = int(self._base_num_elem / (elem_ratio**self._wavelet_order))
        print(self._base_num_elem, self._num_elem)

        self._center_freq = self._base_freq / (elem_ratio**self._wavelet_order)
        # print(self._center_freq)

        # TODO: allow for other number of bits per elem besides 8-bits
        filter_data_type = ""
        input_array_data_type = ""
        if bits_per_elem == 8:
            filter_data_type = "int32"
            input_array_data_type = "int32"
        elif bits_per_elem == 16:
            filter_data_type = "int64"
            input_array_data_type = "int64"
        else:
            sys.exit("exiting: unsupported number of bits")

        self._filter = np.zeros(self._num_elem, dtype=filter_data_type)
        self._input_array = np.zeros(self._num_elem, dtype=input_array_data_type)

        self._scaling_factor = (2**self._bits_per_elem - 1) // 2

        # initialize filter
        self.create_filter()

    def create_filter(self):
        """Initialize elements based on constructor parameters"""

        # if odd, set the center value to 1*scaling factor
        if (self._num_elem % 2) == 1:
            self._filter[self._num_elem // 2] = self._scaling_factor

            for i in range(1, self._num_elem // 2 + 1):
                self._filter[self._num_elem // 2 + i] = self.calculate_tap_value(i)
                self._filter[self._num_elem // 2 - i] = self.calculate_tap_value(i)

        if (self._num_elem % 2) == 0:
            for i in range(1, self._num_elem // 2 + 1):
                self._filter[self._num_elem // 2 + i - 1] = self.calculate_tap_value(i)
                self._filter[self._num_elem // 2 - i] = self.calculate_tap_value(i)

    def calculate_tap_value(self, elem_index):
        """Ricker Equation: r(τ)=(1−1/2 * ω^2 * τ^2)exp(−1/4* ω^2 * τ^2)"""

        w_p = (2 * np.pi) * self._center_freq
        t = elem_index * (1.0 / self._center_freq) / (self._num_elem / 2 + 1.0)

        return (
            (1 - 0.5 * w_p**2 * t**2)
            * np.exp(-0.25 * w_p**2 * t**2)
            * self._scaling_factor
        )

    def print_tap_values(self):
        """Prints tap values to console"""
        print(self._filter)

    def shift_in_value(self, input_value):
        """Shift in the value into the filter bank queue"""
        self._input_array[1:] = self._input_array[:-1]
        self._input_array[0] = input_value

    def compute_output(self):
        """Compute output of the filter for given inputs"""
        return np.dot(self._input_array, self._filter)


class Wavelet_Array:

    """Output represents an array of CWT_FIR's"""

    def __init__(
        self,
        bits_per_elem=8,
        base_num_elem=3,
        base_freq=1,
        elem_ratio=0.577472,
        max_wavelet_order=8,
    ):
        """Initialize an array of wavelets based in input parameters

        Args:
            bits_per_elem (int): number of bits per fir element (e.g. 8 bits)
            base_num_elem (int): number of taps in base fir
            base_freq (int): frequency of smallest or initial fir
            elem_ratio (float): 1/freq_ratio also 1/base_num_elem ratio
            max_wavelet_order (int): this is the number of filters
        """

        self._bits_per_elem = bits_per_elem
        self._elem_ratio = elem_ratio
        self._base_num_elem = base_num_elem
        self._base_freq = base_freq
        self._max_wavelet_order = max_wavelet_order
        self._filter_list = []

        # array of the individual sums of each array
        self._indiv_filter_sums = []

        self.initialize_filter_array()

    def initialize_filter_array(self):
        for wavelet_order in range(0, self._max_wavelet_order):
            self._filter_list.append(
                CWT_FIR(
                    bits_per_elem=self._bits_per_elem,
                    elem_ratio=self._elem_ratio,
                    base_freq=self._base_freq,
                    base_num_elem=self._base_num_elem,
                    wavelet_order=wavelet_order,
                )
            )

    def shift_in_value(self, input_value):
        for filter in self._filter_list:
            filter.shift_in_value(input_value)

    def print_all_filters(self):
        for filter in self._filter_list:
            filter.print_tap_values()

    def calculate_outputs(self):
        for filter in self._filter_list:
            self._indiv_filter_sums.append(filter.compute_output())

    def print_calculated_outputs_per_filter(self):
        print(self._indiv_filter_sums)

    def calculate_total_output(self):
        total = 0
        for sum in self._indiv_filter_sums:
            total += sum
        return total


# test code

# cwt = CWT_FIR(base_num_elem=12)

# cwt.print_tap_values()
wa = Wavelet_Array(base_num_elem=3)
print("print all filters")
wa.print_all_filters()

print("calc outputs")
for t in range(0, 62):
    wa.shift_in_value(127)

wa.calculate_outputs()
wa.print_calculated_outputs_per_filter()
print(wa.calculate_total_output())
