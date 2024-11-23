#ifndef MAIN_H
#define MAIN_H
#include <string>
using std::string;

#include <LibQalculate.h>

Calculator *getCalculator();
std::string qalc_gnuplot_data_dir();
std::string calculate(std::string calculation);

#endif // MAIN_H
