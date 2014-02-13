#ifndef RANDOM_H_
#define RANDOM_H_

class Random{
	Random(bool pseudo = true);
	// Declare random-number generation methods here.
	double random_real();
private:
	int reseed();  //Re-randomize the seed.
	int seed, multiplier, add_on;
};

#endif // !RANDOM_H_
