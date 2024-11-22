#include <libqalculate/qalculate.h>
#include <libqalculate/Calculator.h>

Calculator *getCalculator()
{
    // there's only one global calculator, and you're not supposed to call
    // the Calculator constructor after it's initialized
    if (CALCULATOR == nullptr)
    {
        new Calculator();
    }
    

    return CALCULATOR;
}

std::string qalc_gnuplot_data_dir()
{
    return "";
}
