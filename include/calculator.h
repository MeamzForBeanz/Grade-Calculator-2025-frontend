#ifndef CALCULATOR_H
#define CALCULATOR_H
class Calculator {
public:
  virtual void inputAssignments() = 0;
  virtual void calculateGrade() = 0;
  virtual void displayResults() const = 0;
  virtual ~Calculator() {}
};
#endif // CALCULATOR_H