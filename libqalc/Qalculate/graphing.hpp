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

// Functions of x, explicit y=f(x) equations, and polar
// r=f(theta) curves from zero to at least one revolution (radians). Undefined samples break paths.
GraphSamples sampleGraph(std::string expression, double minX, double maxX, int samples, double maxAngle = 0);

#endif
