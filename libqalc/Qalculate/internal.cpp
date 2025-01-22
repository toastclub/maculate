//
//  internal.cpp
//  maculate
//
//  Created by Evan Boehs on 1/22/25.
//

#include "qalculate.h"

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
