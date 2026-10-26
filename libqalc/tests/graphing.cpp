#include "../Qalculate/graphing.hpp"
#include "../Qalculate/main.hpp"
#include <cassert>
#include <cmath>
#include <future>
#include <iostream>

int main()
{
    auto line = sampleGraph("x", -10, 10, 101);
    assert(line.message.empty() && !line.points.empty());
    for (const auto &p : line.points) assert(std::abs(p.x - p.y) < 1e-10);

    auto quadratic = sampleGraph("x^2", -2, 2, 101);
    assert(quadratic.message.empty() && !quadratic.points.empty());
    for (const auto &p : quadratic.points) assert(std::abs(p.y - p.x * p.x) < 1e-10);

    auto root = sampleGraph("sqrt(x)", -2, 2, 101);
    assert(!root.points.empty());
    for (const auto &p : root.points) assert(p.x >= 0 && std::isfinite(p.y));

    auto reciprocal = sampleGraph("1/x", -1, 1, 1001);
    assert(!reciprocal.points.empty());
    for (size_t i = 1; i < reciprocal.points.size(); ++i) {
        if (reciprocal.points[i - 1].x < 0 && reciprocal.points[i].x > 0)
            assert(reciprocal.points[i].startsSegment);
    }

    // Do not solve equations or turn complex values into real curves.
    assert(sampleGraph("y=x", -2, 2, 101).points.empty());
    assert(sampleGraph("i", -2, 2, 101).points.empty());
    assert(sampleGraph("", -2, 2, 101).points.empty());
    assert(sampleGraph("x", 2, -2, 101).points.empty());
    assert(sampleGraph("x", -2, 2, 1000000).points.empty());

    auto background = std::async(std::launch::async, [] {
        for (int i = 0; i < 5; ++i) assert(!sampleGraph("sin(x)", -10, 10, 101).points.empty());
    });
    for (int i = 0; i < 5; ++i) assert(!calculate("2+2").output.empty());
    background.get();
    assert(calculate("2+2").messages.empty());
    std::cout << "Graph sampling checks passed.\n";
}
