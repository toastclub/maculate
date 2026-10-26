//
//  graphing.cpp
//  maculate
//
//  Created by Evan Boehs on 11/28/24.
//

#include "graphing.hpp"
#include "internal.hpp"

#include <cmath>

GraphSamples sampleGraph(std::string expression, double min, double max, int samples)
{
    GraphSamples result;
    if (!std::isfinite(min) || !std::isfinite(max) || min >= max || samples < 2 || samples > 4096) {
        result.message = "Invalid graph range or sample count.";
        return result;
    }
    if (expression.find_first_not_of(" \t\r\n") == std::string::npos) {
        result.message = "Enter a function of x.";
        return result;
    }

    std::lock_guard<std::recursive_mutex> lock(calculatorMutex());
    Calculator *calc = getCalculator();
    MathStructure xs;
    auto ys = calc->expressionToPlotVector(calc->unlocalizeExpression(expression),
        MathStructure(min), MathStructure(max), samples, &xs, "x", evalops.parse_options, 500);

    bool failed = calc->aborted();
    while (auto *message = calc->message()) {
        if (message->type() == MESSAGE_ERROR) {
            failed = true;
            if (!result.message.empty()) result.message += "\n";
            result.message += message->message();
        }
        calc->nextMessage();
    }
    if (failed) return result;

    bool newSegment = true;
    for (size_t i = 0; i < ys.size() && i < xs.size(); ++i) {
        if (!xs[i].isNumber() || !ys[i].isNumber() ||
            !xs[i].number().isReal() || !ys[i].number().isReal()) {
            newSegment = true;
            continue;
        }
        double x = xs[i].number().floatValue();
        double y = ys[i].number().floatValue();
        if (!std::isfinite(x) || !std::isfinite(y)) {
            newSegment = true;
            continue;
        }
        result.points.push_back({x, y, newSegment});
        newSegment = false;
    }

    // Match the change-of-direction heuristic used by Qalculate's plotVectors
    // continuity check. The sample API does not include these segment breaks.
    for (size_t i = 3; i < result.points.size(); ++i) {
        auto &p = result.points;
        if (p[i].startsSegment || p[i - 1].startsSegment || p[i - 2].startsSegment) continue;
        double d1 = p[i - 2].y - p[i - 3].y;
        double d2 = p[i - 1].y - p[i - 2].y;
        double d3 = p[i].y - p[i - 1].y;
        if (d1 != 0 && d2 != 0 && d3 != 0 &&
            std::signbit(d1) != std::signbit(d2) && std::signbit(d2) != std::signbit(d3)) {
            p[i - 1].startsSegment = true;
        }
    }
    if (result.points.empty()) result.message = "Qalculate returned no real plot data for this expression.";
    return result;
}
