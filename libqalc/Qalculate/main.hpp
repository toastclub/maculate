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

enum CompletionType
{
    FUNCTION,
    VARIABLE,
    UNIT
};

struct Completion
{
    std::string name;
    std::string description;
    CompletionType type;
};

typedef std::vector<Completion> Completions;

std::string qalc_gnuplot_data_dir();
Calculator *getCalculator();
Calculation calculate(std::string calculation);
Completions getCompletions(std::string input);

#endif // MAIN_H
