#include "frb_olympics.hpp"

using namespace std;

namespace frb_olympics {
#if 0
} // emacs pacifier
#endif


// -------------------------------------------------------------------------------------------------
//
// This class is used to generate a vaguely random (not random in any precise sense) sequence of
// uint32_t's, used to set the initial seed of the mersenne twister.
//
// The time (microsec resolution), hostname and PID are all used, to make sure that we end up with
// different seeds on different MPI tasks, or different openmp cores.


struct rng_initializer {
    void generate(uint32_t *p, uint32_t *q) const
    {
	uint32_t pid = getpid();
	struct timeval tv = get_time();

	char hname[HOST_NAME_MAX+2];
	if (gethostname(hname, HOST_NAME_MAX+1) < 0)
	    throw runtime_error("rng_initializer: gethostname() failed");

	hname[HOST_NAME_MAX+1] = 0;   // paranoid
	int hname_len = strlen(hname);

	for (int n = 0; p+n < q; n++) {
	    int m = n % (hname_len+3);
	    uint32_t x;

	    if (m == 0)
		x = tv.tv_usec;
	    else if (m == 1)
		x = tv.tv_sec;
	    else if (m == 2)
		x = pid;
	    else
		x = hname[m-3] * 41399;

	    //
	    // The recurrence below is taken from boost/random/mersenne_twister.hpp
	    // Original reference: http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/emt19937ar.html
	    //
	    uint32_t mask = ~0u;
	    int w = 32;  // should be number of bits in output stream
	    p[n]  = (1812433253UL * (x ^ (x >> (w-2))) + n) & mask;
	}
    }
};


frb_rng::frb_rng() 
{
        
    rng_initializer ri;
    generator.seed(ri);

    //
    // This terrifying reference
    //
    //    L'Ecuyer, Panneton, Matsumoto (2006): Improved Long-Period Generators Based on Linear Recurrences Modulo 2
    //    http://www.iro.umontreal.ca/~lecuyer/myftp/papers/wellrng.pdf
    //
    // seems to suggest that O(10^6) iterations of the RNG are necessary in order to obtain good randomness
    // from a poorly chosen seed.  This may not be necessary given the elaborate seeding implemented in
    // rng_initializer, but I am being paranoid here.  The CPU time needed is ~0.01 sec, which is
    // negligible one-time overhead, but would be death if it occured inside an inner loop.  I think this
    // is generally OK since creating/destroying a lot of RNGs on the fly has its own problems anyway.
    //
    for (int i = 0; i < 1000000; i++)
	generator();
}
    

double frb_rng::uniform(double lo, double hi)
{
    return lo + (hi-lo) * (this->uniform_dist(this->generator));
}

double frb_rng::gaussian()
{
    return this->gaussian_dist(this->generator);
}

}  // namespace frb_olympics