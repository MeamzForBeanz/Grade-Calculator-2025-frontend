#ifndef WEIGHTED_CALCULATOR_H
#define WEIGHTED_CALCULATOR_H
#include "calculator.h"
#include "weighted_assignment.h"
#include <map>
#include <vector>
class WeightedCalculator : public Calculator {
private:
  std::vector<WeightedAssignment> assignments;
  std::map<std::string, float> category_weights;
  float total_weighted_score;
  char earned_grade;

public:
  WeightedCalculator();
  void setGradingScheme(const std::map<std::string, float> &category_weights);
  void inputAssignments() override;
  void calculateGrade() override;
  void displayResults() const override;
};
#endif