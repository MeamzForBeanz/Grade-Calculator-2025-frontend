#ifndef WEIGHTED_ASSIGNMENT_H
#define WEIGHTED_ASSIGNMENT_H
#include "assignment.h"
#include <string>
class WeightedAssignment : public Assignment {
private:
  std::string category;
  float category_weight;

public:
  WeightedAssignment();
  void setCategory(const std::string &category);
  void setCategoryWeight(float category_weight);
  std::string getCategory() const;
  float getCategoryWeight() const;
};
#endif