//
//  graphing.hpp
//  maculate
//
//  Created by Evan Boehs on 11/28/24.
//

#ifndef GRAPHING_H
#define GRAPHING_H
#include <string>
#include <vector>

struct GraphPoint {
    double x;
    double y;
    bool startsSegment;
};

struct GraphSamples {
    std::vector<GraphPoint> points;
    std::string message;
};

// Samples a function of x using Qalculate's plot API. Equations are not solved
// or rewritten; non-real and undefined samples break the curve.
GraphSamples sampleGraph(std::string expression, double min, double max, int samples);

#endif
