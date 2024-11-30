// The purpose of this library is to delegate all unsafe operations to C++,
// and keep the processing of safe data in Swift.

#include "LibQalculate.h"
#include "main.hpp"
#include <iostream>
#include <sstream>
#include <unordered_map>

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
    evalops.warn_about_denominators_assumed_nonzero = true;

    evalops.approximation = APPROXIMATION_TRY_EXACT;

    printops.digit_grouping = DIGIT_GROUPING_NONE;

    CALCULATOR->setPrecision(16);

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
            if (auto *mathFunction = dynamic_cast<MathFunction *>(c))
            {
                std::string value = mathFunction->name() + "()";
                std::string args;
                for (size_t i = 1; i <= mathFunction->lastArgumentDefinitionIndex(); i++)
                {
                    if (i > 1)
                        args += ", ";
                    args += mathFunction->getArgumentDefinition(i)->copy()->name();
                }
                completions.push_back({value, mathFunction->title(), type, args});
            }
            else
            {
                // Handle generic ExpressionItem logic
                completions.push_back({c->name(), c->title(), type, ""});
            }
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

    while ((message = calculator->message()))
    {
        printf("Message: %s\n", message->message().c_str());
        auto msgType = message->type();
        std::string severity = msgType == MESSAGE_INFORMATION ? "Info" : msgType == MESSAGE_WARNING ? "Warning"
                                                                                                    : "Error";
        ret.messages += severity + ": " + message->message() + "\n";
        calculator->nextMessage();
    }

    return ret;
}

bool injectCurrencies(std::string currencies)
{
    // currencies are in the format "USD:1.23\n", iterate over them
    std::unordered_map<std::string, std::string> currencyMap;
    std::istringstream stream(currencies);
    std::string line;

    while (std::getline(stream, line))
    {
        size_t delimiterPos = line.find(':');
        if (delimiterPos == std::string::npos)
        {
            std::cerr << "Invalid format: " << line << '\n';
            return false;
        }
        std::string currencyCode = line.substr(0, delimiterPos);
        std::string valueStr = line.substr(delimiterPos + 1);
        currencyMap[currencyCode] = valueStr;
    }

    Calculator *calc = getCalculator();
    Unit *u_euro = calc->getUnit("EUR");

    // https://github.com/Qalculate/libqalculate/blob/0d81784d2c85ca90b5a660b70862b9572be661e3/libqalculate/Calculator-definitions.cc#L3588-L3610
    for (const auto &[currency, rate] : currencyMap)
        if (!rate.empty())
        {
            std::string _rate = "1/" + rate;
            Unit *u = calc->getUnit(currency);
            if (!u)
            {
                u = calc->addUnit(new AliasUnit("Currency", currency, "", "", "", u_euro, _rate, 1, "", false, true));
            }
            else if (u->subtype() == SUBTYPE_ALIAS_UNIT)
            {
                ((AliasUnit *)u)->setBaseUnit(u_euro);
                ((AliasUnit *)u)->setExpression(rate);
            }
            if (u)
            {
                u->setApproximate();
                u->setPrecision(-2);
                u->setChanged(false);
            }
        }
    calc->setExchangeRatesWarningEnabled(false);
    return true;
}

std::string qalc_gnuplot_data_dir()
{
    return "";
}
