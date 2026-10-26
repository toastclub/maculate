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

    // Explicit equations use the same sampler, without symbolic solving.
    for (auto expression : {"y=x", "y=1-x", "r=2", "r=1+cos(theta)", "r=1+cos(θ)",
                            "2*sin(3*theta)", "r=2sin(3θ)", "r=sin(theta)+cos(theta)"}) {
        auto graph = sampleGraph(expression, -2, 2, 501);
        assert(graph.message.empty() && !graph.points.empty());
        for (auto p : graph.points) {
            if (std::string(expression) == "y=1-x") assert(std::abs(p.x+p.y-1) < 1e-8);
            if (std::string(expression) == "r=2") assert(std::abs(std::hypot(p.x,p.y)-2) < 1e-8);
        }
    }
    auto cardioid = sampleGraph("r=1+cos(theta)", -2, 2, 501);
    for (auto p : cardioid.points) {
        double radius = std::hypot(p.x,p.y);
        if (radius > 1e-8) assert(std::abs(radius-1-p.x/radius) < 1e-8);
    }
    auto rose = sampleGraph("r=2sin(3θ)", -2, 2, 501);
    double maxRadius = 0;
    for (auto p : rose.points) maxRadius = std::max(maxRadius, std::hypot(p.x,p.y));
    assert(maxRadius > 1.9 && maxRadius <= 2.000001);

    for (auto expression : {"x+y=1", "x^2+y^2=1", "x=2", "y=x+y", "r=r+theta", "x+y<1", "r=i", "i", ""})
        assert(sampleGraph(expression, -2, 2, 101).points.empty());
    assert(sampleGraph("x", 2, -2, 101).points.empty());
    assert(sampleGraph("x", -2, 2, 1000000).points.empty());

    auto background = std::async(std::launch::async, [] {
        for (auto expression : {"sin(x)", "y=1-x", "r=1+cos(theta)"})
            assert(!sampleGraph(expression, -10, 10, 101).points.empty());
    });
    for (int i = 0; i < 5; ++i) assert(!calculate("2+2").output.empty());
    background.get();
    assert(calculate("2+2").messages.empty());
    std::cout << "Graph sampling checks passed.\n";
}
