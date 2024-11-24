// The purpose of this library is to delegate all unsafe operations to C++,
// and keep the processing of safe data in Swift.

#include "LibQalculate.h"
#include "main.hpp"
#include <iostream>

EvaluationOptions evalops;
PrintOptions printops;
ParseOptions parseops;

int init()
{
    CALCULATOR->loadGlobalDefinitions();
    printops.use_unicode_signs = true;
    printops.interval_display = INTERVAL_DISPLAY_SIGNIFICANT_DIGITS;
    printops.base_display = BASE_DISPLAY_NORMAL;
    printops.digit_grouping = DIGIT_GROUPING_STANDARD;
    printops.indicate_infinite_series = true;
    evalops.parse_options.angle_unit = ANGLE_UNIT_RADIANS;
    evalops.parse_options.unknowns_enabled = false;
    return 0;
}

Calculator *getCalculator()
{
    // there's only one global calculator, and you're not supposed to call
    // the Calculator constructor after it's initialized
    if (CALCULATOR == nullptr)
    {
        new Calculator();
        init();
    }

    return CALCULATOR;
}

// text input suggestions
Completions getCompletions(std::string input)
{
    Calculator *calc = getCalculator();
    Completions completions;

    auto addCompletions = [&](auto &collection, CompletionType type)
    {
        for (auto &c : collection)
        {
            if (c->name().find(input) != 0)
                continue;

            // Check if it's a MathFunction
            /*if (auto *mathFunction = dynamic_cast<MathFunction *>(c))
            {
            }*/

            // Handle generic ExpressionItem logic
            completions.push_back({c->name(), c->title(), type});
        }
    };

    addCompletions(calc->functions, CompletionType::FUNCTION);
    addCompletions(calc->variables, CompletionType::VARIABLE);
    addCompletions(calc->units, CompletionType::UNIT);

    return completions;
}

Calculation calculate(std::string calculation)
{
    Calculator *calc = getCalculator();
    calculation = calc->unlocalizeExpression(calculation);
    std::string parsed_str;
    bool resultIsComparison;
    auto result = calc->calculateAndPrint(calculation, 1000, evalops, printops, AUTOMATIC_FRACTION_AUTO, AUTOMATIC_APPROXIMATION_AUTO, &parsed_str, -1, &resultIsComparison, true, 2, TAG_TYPE_HTML);

    Calculation ret;
    ret.input = parsed_str;
    ret.output = result;
    CalculatorMessage *message;
    if ((message = calculator->message()))
    {
        auto msgType = message->type();
        std::string severity = msgType == MESSAGE_INFORMATION ? "Info" : msgType == MESSAGE_WARNING ? "Warning"
                                                                                                    : "Error";
        ret.messages += severity + ": " + message->message() + "\n";
    }

    return ret;
}

std::string qalc_gnuplot_data_dir()
{
    return "";
}
