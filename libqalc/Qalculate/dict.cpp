//
//  dict.cpp
//  maculate
//
//  Created by Evan Boehs on 1/22/25.
//

#include "qalculate.h"
#include "internal.hpp"
#include "dict.hpp"

std::string to_html_escaped(const std::string strpre)
{
    std::string str = strpre;
    // if (printops.use_unicode_signs)
    if (true)
    {
        gsub(">=", SIGN_GREATER_OR_EQUAL, str);
        gsub("<=", SIGN_LESS_OR_EQUAL, str);
        gsub("!=", SIGN_NOT_EQUAL, str);
        gsub("...", "…", str);
    }
    gsub("&", "&amp;", str);
    gsub("<", "&lt;", str);
    gsub(">", "&gt;", str);
    gsub("\n", "\n", str);
    return str;
}

DictItems getDictItems(DictType type)
{
    Calculator *calc = getCalculator();
    DictItems items;

    auto processItems = [&items](auto &container)
    {
        for (auto &entry : container)
        {
            items.push_back({entry->name(), entry->title(), entry->category()});
        }
    };

    switch (type)
    {
    case DICT_TYPE_FUNCTION:
        processItems(calc->functions);
        break;
    case DICT_TYPE_UNIT:
        processItems(calc->units);
        break;
    }

    // print items
    for (auto &item : items)
    {
        std::cout << item.key << " " << item.value << " " << item.categories << std::endl;
    }
    return items;
}

// https://github.com/Qalculate/qalculate-qt/blob/72e4a2dacd3c4787d4c7c0afa272b52d6d5b2c81/src/functionsdialog.cpp#L364
std::string generateFunctionBody(MathFunction *f)
{
    // The function name
    std::string str = "";
    const ExpressionName *ename = &f->preferredName();
    str = "***";
    str += ename->formattedName(TYPE_FUNCTION, true, true);
    str += "**(";
    // Add arguments
    int iargs = f->maxargs();
    if (iargs < 0)
    {
        iargs = f->minargs() + 1;
        if ((int)f->lastArgumentDefinitionIndex() > iargs)
            iargs = (int)f->lastArgumentDefinitionIndex();
    }
    for (int i = 0; i < iargs; i++)
    {
        if (i > f->minargs())
            str += "[";
        if (i > 1)
            str += CALCULATOR->getComma() + " ";

        const auto *arg = f->getArgumentDefinition(i);
        if (arg && !arg->name().empty())
            str += arg->name();
        else
        {
            // str += "argument";
            // if (i > 1 || f->maxargs() != 1)
            // str += " " + i2s(i);
        }

        if (i > f->minargs())
            str += "]";
    }
    if (f->maxargs() < 0)
        str += CALCULATOR->getComma() + " …";
    str += ")";
    // Add alternative names
    for (size_t i = 1; i <= f->countNames(); i++)
        if (&f->getName(i) != ename)
            str += "\n" + f->getName(i).formattedName(TYPE_FUNCTION, true, true);
    str += "*\n";
    // Add description
    if (!f->description().empty())
    {
        str += "\n" + to_html_escaped(f->description()) + "\n";
    }
    // Add example
    if (!f->example(true).empty())
        str += "\nExample: " + to_html_escaped(f->example(false, ename->formattedName(TYPE_FUNCTION, true)));
    +"\n";
    // Add copyright
    if (f->subtype() == SUBTYPE_DATA_SET && !((DataSet *)f)->copyright().empty())
        str += "\n" + to_html_escaped(((DataSet *)f)->copyright()) + "\n";

    Argument default_arg;
    Argument *arg;
    if (iargs)
    {
        str += "\n**Arguments:**\n";
        for (int i = 1; i <= iargs; i++)
        {
            arg = f->getArgumentDefinition(i);
            if (arg && !arg->name().empty())
                str += arg->name();
            else
                str += i2s(i);
            str += ": *";
            if (arg)
                str += arg->printlong();
            else
            {
                str += default_arg.printlong();
            }
            if (i > f->minargs())
            {
                str += " (";
                str += "optional";
                if (!f->getDefaultValue(i).empty() && f->getDefaultValue(i) != "\"\"")
                {
                    str += ", argument default ";
                    /*ParseOptions pa = settings->evalops.parse_options;
                    pa.base = 10;
                    std::string str2 = CALCULATOR->localizeExpression(f->getDefaultValue(i), pa);
                    gsub("*", settings->multiplicationSign(), str2);
                    gsub("/", settings->divisionSign(false), str2);
                    gsub("-", SIGN_MINUS, str2);
                    str += str2;*/
                }
                str += ")";
            }
            str += "*\n";
        }
    }
    if (!f->condition().empty())
    {
        str += "\nRequired Condition:" + to_html_escaped(f->printCondition()) + "\n";
    }
    return str;
}

std::string getBodyForItem(const DictItem &item)
{
    Calculator *calc = getCalculator();
    std::string str = "";
    switch (item.type)
    {
    case DICT_TYPE_FUNCTION:
    {
        MathFunction *f = calc->getFunction(item.key);
        if (f)
        {
            str = generateFunctionBody(f);
        }
        break;
    }
    }
    return str;
}

std::string getBodyForItem(const std::string &key, DictType type)
{
    DictItem item = {key, "", "", type};
    return getBodyForItem(item);
}
