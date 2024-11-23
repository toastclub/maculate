#ifndef MAIN_H
#define MAIN_H
#include <string>
using std::string;

struct Calculation
{
    std::string input;
    std::string output;
    std::string messages;
};

std::string qalc_gnuplot_data_dir();
Calculation calculate(std::string calculation);

#endif // MAIN_H
