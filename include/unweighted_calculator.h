#ifndef UNWEIGHTED_CALCULATOR_H
#define UNWEIGHTED_CALCULATOR_H
#include "assignment.h"
#include "calculator.h"
#include <string>
#include <vector>

class UnweightedCalculator : public Calculator {
private:
  int total_course_points;
  float total_points_earned;
  float total_percentage_earned;
  float A_points, B_points, C_points, D_points;
  float A_percentage, B_percentage, C_percentage, D_percentage;
  char earned_grade;
  std::vector<Assignment> assignments;

public:
  UnweightedCalculator();
  void setGradingScheme(int total_course_points, float A_points, float B_points,
                        float C_points, float D_points);
  void inputAssignments() override;
  void calculateGrade() override;
  void displayResults() const override;
};

#endif