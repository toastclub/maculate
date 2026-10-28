//
//  internal.hpp
//  maculate
//
//  Created by Evan Boehs on 1/22/25.
//

#ifndef INTERNAL_H
#define INTERNAL_H
#include <qalculate.h>
#include <mutex>

Calculator *getCalculator();
std::recursive_mutex &calculatorMutex();

extern EvaluationOptions evalops;
extern PrintOptions printops;
extern ParseOptions parseops;

#endif // INTERNAL_H
