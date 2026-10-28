//
//  graphing.cpp
//  maculate
//
//  Created by Evan Boehs on 11/28/24.
//

#include "graphing.hpp"
#include "internal.hpp"

#include <cmath>
#include <regex>

namespace {
// Qalculate treats bare θ as its Heaviside function and r as a unit. Escape
// only these coordinate names, retaining normal parsing for functions and units.
std::string polarCoordinates(const std::string &expression)
{
    static const std::regex theta(R"((^|[^a-zA-Z_\\])\\?(theta\b|θ))");
    static const std::regex radius(R"((^|[^a-zA-Z_\\])\\?r\b)");
    return std::regex_replace(std::regex_replace(expression, theta, "$1\\θ"), radius, "$1\\r");
}
}

GraphSamples sampleGraph(std::string expression, double min, double max, int samples)
{
    GraphSamples result;
    if (!std::isfinite(min) || !std::isfinite(max) || min >= max || samples < 2 || samples > 4096) {
        result.message = "Invalid graph range or sample count.";
        return result;
    }
    if (expression.find_first_not_of(" \t\r\n") == std::string::npos) {
        result.message = "Enter a function or equation.";
        return result;
    }

    std::lock_guard<std::recursive_mutex> lock(calculatorMutex());
    Calculator *calc = getCalculator();
    auto normalized = polarCoordinates(calc->unlocalizeExpression(expression));
    bool polar = normalized.find("\\θ") != std::string::npos || normalized.find("\\r") != std::string::npos;
    ParseOptions po = evalops.parse_options;
    po.unknowns_enabled = polar;
    if (normalized.find_first_of("=<>") != std::string::npos) {
        auto parsed = calc->parse(normalized, po);
        MathStructure coordinate = polar ? MathStructure("r", true)
            : MathStructure(calc->getActiveVariable("y"));
        if (parsed.isComparison() && parsed.comparisonType() == COMPARISON_EQUALS &&
            parsed[0].equals(coordinate) && !parsed[1].contains(coordinate)) {
            normalized = parsed[1].print(calc->save_printoptions);
        } else {
            result.message = "Use y=f(x) or r=f(theta) to graph an equation.";
        }
    }
    MathStructure xs, ys;
    if (result.message.empty()) {
        ys = calc->expressionToPlotVector(normalized,
            MathStructure(polar ? 0.0 : min), MathStructure(polar ? 2 * std::acos(-1.0) : max),
            samples, &xs, polar ? "θ" : "x", po, 500);
    }

    bool failed = calc->aborted() || !result.message.empty();
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
    if (polar) {
        for (auto &p : result.points) {
            const double angle = p.x, radius = p.y;
            p = {radius * std::cos(angle), radius * std::sin(angle), p.startsSegment};
        }
    }
    if (result.points.empty()) result.message = "Qalculate returned no real plot data for this expression.";
    return result;
}
