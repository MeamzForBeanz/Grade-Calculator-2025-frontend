#include "unweighted_calculator.h"
#include <iomanip>
#include <iostream>

UnweightedCalculator::UnweightedCalculator()
    : total_course_points(0), total_points_earned(0.0f),
      total_percentage_earned(0.0f), earned_grade('F') {}
void UnweightedCalculator::setGradingScheme(int total_points, float a_points, float b_points, float c_points, float d_points) {
  total_course_points = total_points;
  A_points = a_points;
  B_points = b_points;
  C_points = c_points;
  D_points = d_points;
  A_percentage = (A_points / total_course_points) * 100;
  B_percentage = (B_points / total_course_points) * 100;
  C_percentage = (C_points / total_course_points) * 100;
  D_percentage = (D_points / total_course_points) * 100;
}

void UnweightedCalculator::inputAssignments() {
  std::string assignment_name;
  float points_possible, points_earned;
  bool is_bonus;
  
  std::cout << "Grade Calculation\n";
  std::cout << "Enter assignments (input 'done' or 'Done' to finish):\n\n";
  
  while (true) {
    std::cout << "Enter assignment name or 'done' to finish: ";
    std::getline(std::cin >> std::ws, assignment_name);
    if (assignment_name == "done" || assignment_name == "Done") {
      break;
    }
    
    Assignment assignment;
    assignment.setName(assignment_name);
    std::cout << "Enter points possible for " << assignment_name << ": ";
    std::cin >> points_possible;
    assignment.setPointsPossible(points_possible);
    std::cout << "Enter points earned for " << assignment_name << ": ";
    std::cin >> points_earned;
    assignment.setPointsEarned(points_earned);
    std::cout << "Is this a bonus assignment? (1 for Yes, 0 for No): ";
    std::cin >> is_bonus;
    assignment.setBonus(is_bonus);
    assignments.push_back(assignment);
  }
}
void UnweightedCalculator::calculateGrade() {
  total_points_earned = 0.0f;
  float bonus_points = 0.0f;
  
  for (const Assignment &assignment : assignments) {
    if (assignment.isBonus()) {
      bonus_points += assignment.getPointsEarned();
    } else {
      total_points_earned += assignment.getPointsEarned();
    }
  }
  
  total_percentage_earned = (total_points_earned / total_course_points) * 100;
  total_percentage_earned += (bonus_points / total_course_points) * 100;
  
  if (total_percentage_earned >= A_percentage) {
    earned_grade = 'A';
  } else if (total_percentage_earned >= B_percentage) {
    earned_grade = 'B';
  } else if (total_percentage_earned >= C_percentage) {
    earned_grade = 'C';
  } else if (total_percentage_earned >= D_percentage) {
    earned_grade = 'D';
  } else {
    earned_grade = 'F';
  }
}

void UnweightedCalculator::displayResults() const {
  std::cout << std::fixed << std::setprecision(2);
  std::cout << "\nUnweighted Grade Calculation Results\n";
  std::cout << "------------------------------------\n";
  
  for (const Assignment &assignment : assignments) {
    float percentage =
        (assignment.getPointsEarned() / assignment.getPointsPossible()) * 100;
    std::cout << "Assignment: " << assignment.getName()
              << "\n Points Earned: " << assignment.getPointsEarned()
              << "\n Points Possible: " << assignment.getPointsPossible()
              << "\n Percentage: " << percentage << "%"
              << "\n Bonus: " << (assignment.isBonus() ? "Yes" : "No")
              << "\n\n";
  }
  
  float bonus_points = 0.0f;
  for (const Assignment &assignment : assignments) {
    if (assignment.isBonus()) {
      bonus_points += assignment.getPointsEarned();
    }
  }
  
  std::cout << "Regular Points Earned: " << total_points_earned << "\n"
            << "Bonus Points Earned: " << bonus_points << "\n"
            << "Total Points (Including Bonus): "
            << (total_points_earned + bonus_points) << "\n"
            << "Total Course Points: " << total_course_points << "\n"
            << "Final Percentage: " << total_percentage_earned << "%\n"
            << "Final Letter Grade: " << earned_grade << "\n";
}