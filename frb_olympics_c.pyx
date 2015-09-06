import numpy as np
cimport numpy as np
from libcpp.string cimport string

cimport _frb_olympics_c


cdef class frb_rng:
    cdef _frb_olympics_c.frb_rng *_rng

    def __cinit__(self):
        self._rng = NULL

    def __init__(self, *args):
        if len(args) == 0:
            self._rng = new _frb_olympics_c.frb_rng()
        elif len(args) == 1:
            self._construct_from_rng(args[0])
        else:
            raise RuntimeError('frb_rng constructor syntax is either frb_rng() or frb_rng(existing_rng)')

    def _construct_from_rng(self, frb_rng r):
        assert r._rng != NULL
        self._rng = new _frb_olympics_c.frb_rng(r._rng[0])

    def __dealloc__(self):
        if self._rng != NULL:
            del self._rng
            self._rng = NULL

    def uniform(self, lo, hi):
        assert self._rng != NULL
        return self._rng.uniform(lo, hi)

    def gaussian(self):
        assert self._rng != NULL
        return self._rng.gaussian()


cdef class frb_pulse:
    cdef _frb_olympics_c.frb_pulse *_pulse

    def __cinit__(self):
        self._pulse = NULL

    def __init__(self, fluence, arrival_time, intrinsic_width, dispersion_measure, scattering_measure, spectral_index):
        self._pulse = new _frb_olympics_c.frb_pulse(fluence, arrival_time, intrinsic_width, dispersion_measure, scattering_measure, spectral_index)
     	 
    def __dealloc__(self):
        if self._pulse != NULL:
            del self._pulse
            self._pulse = NULL


    def get_signal_to_noise_in_channel(self, freq_lo_MHz, freq_hi_MHz, dt_sample):
        assert self._pulse != NULL
        return self._pulse.get_signal_to_noise_in_channel(freq_lo_MHz, freq_hi_MHz, dt_sample)
     
    def add_to_timestream(self, freq_lo_MHz, freq_hi_MHz, np.ndarray[float,ndim=1,mode='c'] timestream not None, dt_sample, ichunk):
        assert self._pulse != NULL
        self._pulse.add_to_timestream(freq_lo_MHz, freq_hi_MHz, &timestream[0], timestream.shape[0], dt_sample, ichunk)

    def __repr__(self):
        return ('frb_pulse(fluence=%s, arrival_time=%s, width=%s, dm=%s, sm=%s, beta=%s)' 
                % (self.fluence, self.arrival_time, self.intrinsic_width, self.dispersion_measure,
                   self.scattering_measure, self.spectral_index))


    property fluence:
        def __get__(self):
            assert self._pulse != NULL
            return self._pulse.fluence
        def __set__(self, x):
            assert self._pulse != NULL
            self._pulse.fluence = <double> x

    property spectral_index:
        def __get__(self):
            assert self._pulse != NULL
            return self._pulse.spectral_index
        def __set__(self, x):
            assert self._pulse != NULL
            self._pulse.spectral_index = <double> x

    property arrival_time:
        def __get__(self):
            assert self._pulse != NULL
            return self._pulse.arrival_time
        def __set__(self, x):
            assert self._pulse != NULL
            self._pulse.arrival_time = <double> x

    property intrinsic_width:
        def __get__(self):
            assert self._pulse != NULL
            return self._pulse.intrinsic_width
        def __set__(self, x):
            assert self._pulse != NULL
            self._pulse.intrinsic_width = <double> x

    property dispersion_measure:
        def __get__(self):
            assert self._pulse != NULL
            return self._pulse.dispersion_measure
        def __set__(self, x):
            assert self._pulse != NULL
            self._pulse.dispersion_measure = <double> x

    property scattering_measure:
        def __get__(self):
            assert self._pulse != NULL
            return self._pulse.scattering_measure
        def __set__(self, x):
            assert self._pulse != NULL
            self._pulse.scattering_measure = <double> x


cdef class frb_search_params:
    cdef _frb_olympics_c.frb_search_params *_params

    def __cinit__(self):
        self._params = NULL

    def __init__(self, *args):
        if (len(args)==1) and (args[0] is None):
            return   # hack for frb_search_algorithm_base.
        elif (len(args)==1) and isinstance(args[0], basestring):
            self._construct_from_filename(args[0])
        elif (len(args)==1) and isinstance(args[0], frb_search_params):
            self._construct_from_existing_params(args[0])
        else:
            raise RuntimeError("allowed constructor syntaxes are: frb_search_params(filename) or frb_search_params(existing_params)")

    def _construct_from_filename(self, string filename):
        self._params = new _frb_olympics_c.frb_search_params(filename)

    def _construct_from_existing_params(self, frb_search_params p):
        assert p._params != NULL
        self._params = new _frb_olympics_c.frb_search_params(p._params[0])

    def __dealloc__(self):
        if self._params != NULL:
            del self._params
            self._params = NULL


    def make_random_pulse(self, frb_rng rng, fluence):
        assert rng._rng != NULL
        assert self._params != NULL

        cdef _frb_olympics_c.frb_pulse p = self._params.make_random_pulse(rng._rng[0], fluence)
        return frb_pulse(p.fluence, p.arrival_time, p.intrinsic_width, p.dispersion_measure, p.scattering_measure, p.spectral_index)


    def get_allowed_arrival_times(self, intrinsic_width, dm, sm):
        assert self._params != NULL

        cdef double t0 = 0.0
        cdef double t1 = 0.0
        self._params.get_allowed_arrival_times(t0, t1, intrinsic_width, dm, sm)
        return (t0, t1)


    def simulate_noise(self, frb_rng r, np.ndarray[float,ndim=2,mode='c'] timestream not None):
        assert r._rng != NULL
        assert self._params != NULL
        assert timestream.shape[0] == self.nchan
        assert timestream.shape[1] == self.nsamples_per_chunk
        self._params.simulate_noise(r._rng[0], &timestream[0,0])


    def add_pulse(self, frb_pulse p, np.ndarray[float,ndim=2,mode='c'] timestream not None, ichunk):
        assert p._pulse != NULL	
        assert self._params != NULL
        assert timestream.shape[0] == self.nchan
        assert timestream.shape[1] == self.nsamples_per_chunk
        self._params.add_pulse(p._pulse[0], &timestream[0,0], ichunk)


    def get_signal_to_noise_of_pulse(self, frb_pulse p):
        assert p._pulse != NULL
        assert self._params != NULL
        return self._params.get_signal_to_noise_of_pulse(p._pulse[0])


    property dm_min:
        def __get__(self):
            assert self._params != NULL
            return self._params.dm_min
        def __set__(self, x):
            assert self._params != NULL
            self._params.dm_min = <double> x

    property dm_max:
        def __get__(self):
            assert self._params != NULL
            return self._params.dm_max
        def __set__(self, x):
            assert self._params != NULL
            self._params.dm_max = <double> x

    property sm_min:
        def __get__(self):
            assert self._params != NULL
            return self._params.sm_min
        def __set__(self, x):
            assert self._params != NULL
            self._params.sm_min = <double> x

    property sm_max:
        def __get__(self):
            assert self._params != NULL
            return self._params.sm_max
        def __set__(self, x):
            assert self._params != NULL
            self._params.sm_max = <double> x

    property beta_min:
        def __get__(self):
            assert self._params != NULL
            return self._params.beta_min
        def __set__(self, x):
            assert self._params != NULL
            self._params.beta_min = <double> x

    property beta_max:
        def __get__(self):
            assert self._params != NULL
            return self._params.beta_max
        def __set__(self, x):
            assert self._params != NULL
            self._params.beta_max = <double> x

    property width_min:
        def __get__(self):
            assert self._params != NULL
            return self._params.width_min
        def __set__(self, x):
            assert self._params != NULL
            self._params.width_min = <double> x

    property width_max:
        def __get__(self):
            assert self._params != NULL
            return self._params.width_max
        def __set__(self, x):
            assert self._params != NULL
            self._params.width_max = <double> x

    property nchan:
        def __get__(self):
            assert self._params != NULL
            return self._params.nchan
        def __set__(self, x):
            assert self._params != NULL
            self._params.nchan = <int> x

    property band_freq_lo_MHz:
        def __get__(self):
            assert self._params != NULL
            return self._params.band_freq_lo_MHz
        def __set__(self, x):
            assert self._params != NULL
            self._params.band_freq_lo_MHz = <double> x

    property band_freq_hi_MHz:
        def __get__(self):
            assert self._params != NULL
            return self._params.band_freq_hi_MHz
        def __set__(self, x):
            assert self._params != NULL
            self._params.band_freq_hi_MHz = <double> x

    property dt_sample:
        def __get__(self):
            assert self._params != NULL
            return self._params.dt_sample
        def __set__(self, x):
            assert self._params != NULL
            self._params.dt_sample = <double> x

    property nsamples_tot:
        def __get__(self):
            assert self._params != NULL
            return self._params.nsamples_tot
        def __set__(self, x):
            assert self._params != NULL
            self._params.nsamples_tot = <int> x

    property nsamples_per_chunk:
        def __get__(self):
            assert self._params != NULL
            return self._params.nsamples_per_chunk
        def __set__(self, x):
            assert self._params != NULL
            self._params.nsamples_per_chunk = <int> x

    property nchunks:
        def __get__(self):
            assert self._params != NULL
            return self._params.nchunks
        def __set__(self, x):
            assert self._params != NULL
            self._params.nchunks = <int> x


cdef class frb_search_algorithm_base:
    cdef _frb_olympics_c.frb_search_algorithm_base *_p

    def __cinit__(self):
        self._p = NULL

    def __dealloc__(self):
        if self._p != NULL:
            del self._p
            self._p = NULL

    def search_start(self):
        assert self._p != NULL
        self._p.search_start()

    def _search_chunk1(self, np.ndarray[float,ndim=2,mode='c'] chunk not None, int ichunk):
        assert chunk.shape[0] == self.search_params.nchan
        assert chunk.shape[1] == self.search_params.nsamples_per_chunk
        self._p.search_chunk(&chunk[0,0], ichunk, NULL)

    def _search_chunk2(self, np.ndarray[float,ndim=2,mode='c'] chunk not None, int ichunk, np.ndarray[float,ndim=2,mode='c'] debug_buffer not None):
        assert chunk.shape[0] == self.search_params.nchan
        assert chunk.shape[1] == self.search_params.nsamples_per_chunk
        assert debug_buffer.shape[0] == self.debug_buffer_ndm
        assert debug_buffer.shape[1] == self.debug_buffer_nt
        self._p.search_chunk(&chunk[0,0], ichunk, &debug_buffer[0,0])

    def search_chunk(self, chunk, ichunk, debug_buffer=None):
        assert self._p != NULL
        if debug_buffer is None:
            self._search_chunk1(chunk, ichunk)
        else:
            self._search_chunk2(chunk, ichunk, debug_buffer)

    def search_end(self):
        assert self._p != NULL
        self._p.search_end()


    property search_params:
        def __get__(self):
            assert self._p != NULL
            cdef _frb_olympics_c.frb_search_params *sp = new _frb_olympics_c.frb_search_params(self._p[0].p)
            ret = frb_search_params(None)
            ret._params = sp
            return ret

    property name:
        def __get__(self):
            assert self._p != NULL
            return self._p.name

    property debug_buffer_ndm:
        def __get__(self):
            assert self._p != NULL
            return self._p.debug_buffer_ndm

    property debug_buffer_nt:
        def __get__(self):
            assert self._p != NULL
            return self._p.debug_buffer_nt

    property search_gb:
        def __get__(self):
            assert self._p != NULL
            return self._p.search_gb

    property search_result:
        def __get__(self):
            assert self._p != NULL
            return self._p.search_result
        def __set__(self, x):
            assert self._p != NULL
            self._p.search_result = <double> x


def simple_direct(frb_search_params p, epsilon):
    assert p._params != NULL
    cdef _frb_olympics_c.frb_search_algorithm_base *ap = _frb_olympics_c.simple_direct(p._params[0], epsilon)
    ret = frb_search_algorithm_base()
    ret._p = ap
    return ret


def simple_tree(frb_search_params p, depth, nsquish):
    assert p._params != NULL
    cdef _frb_olympics_c.frb_search_algorithm_base *ap = _frb_olympics_c.simple_tree(p._params[0], depth, nsquish)
    ret = frb_search_algorithm_base()
    ret._p = ap
    return ret


def sloth(frb_search_params p, epsilon, nupsample=1):
    assert p._params != NULL
    cdef _frb_olympics_c.frb_search_algorithm_base *ap = _frb_olympics_c.sloth(p._params[0], epsilon, nupsample)
    ret = frb_search_algorithm_base()
    ret._p = ap
    return ret


def bonsai(frb_search_params p, depth, nupsample=1):
    assert p._params != NULL
    cdef _frb_olympics_c.frb_search_algorithm_base *ap = _frb_olympics_c.bonsai(p._params[0], depth, nupsample)
    ret = frb_search_algorithm_base()
    ret._p = ap
    return ret