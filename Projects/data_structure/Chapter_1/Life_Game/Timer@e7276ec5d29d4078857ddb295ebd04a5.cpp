#include "Timer.h"

Timer::Timer()
{
	startTime = clock();
}
double Timer::elapsedTime()
{
	clock_t endTime = clock();
}