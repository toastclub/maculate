#include <libqalculate/qalculate.h>

Calculator* getCalculator() {
    // there's only one global calculator, and you're not supposed to call
    // the Calculator constructor after it's initialized
    if (CALCULATOR == nullptr) {
        new Calculator();
    }
    return CALCULATOR;
}

std::string qalc_gnuplot_data_dir() {
    return "";
}
bool qalc_invoke_gnuplot(
    std::vector<std::pair<std::string, std::string>> data_files,
    std::string commands, std::string extra, bool persist) {
    val data_obj = val::object();
    for (auto file : data_files) {
        data_obj.set(file.first, file.second);
    }
    return val::global("runGnuplot").call<bool>("call", val::undefined(), data_obj, commands, extra, persist);
}
