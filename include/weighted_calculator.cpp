#include "weighted_calculator.h"
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>

WeightedCalculator::WeightedCalculator()
    : total_weighted_score(0.0f), earned_grade('F') {}

void WeightedCalculator::setGradingScheme(
    const std::map<std::string, float> &category_weights) {
  this->category_weights = category_weights;
}

void WeightedCalculator::inputAssignments() {
  if (category_weights.empty()) {
    std::cerr << "No categories have been set. Please set the grading scheme "
                 "first.\n";
    return;
  }
  
  std::string assignment_name;
  float assignment_score;
  float assignment_possible;
  bool assignment_bonus;
  std::cout << "Grade Calculation\n";
  std::cout << "You will be prompted to input scores for all assignments.\n"
            << "(Input 'done' or 'Done' to finish input and calculate the "
               "letter grade.)\n\n";
  
  std::vector<std::string> category_list;
  for (const auto &category : category_weights) {
    category_list.push_back(category.first);
  }
  
  bool score_input = true;
  
  while (score_input) {
    std::cout << "Please input the assignment name or 'done' to quit: ";
    std::getline(std::cin >> std::ws, assignment_name);
    if (assignment_name == "done" || assignment_name == "Done") {
      score_input = false;
      continue;
    }
    
    WeightedAssignment assignment;
    
    assignment.setName(assignment_name);
    std::cout << "Please choose a category for " << assignment_name << ":\n";
    
    for (int i = 0; i < category_list.size(); ++i) {
      std::cout << i + 1 << ". " << category_list[i]
                << " (Weight: " << category_weights.at(category_list[i])
                << ")\n";
    }
    
    int category_choice;
    std::cin >> category_choice;
    
    while (std::cin.fail() || category_choice < 1 ||
           category_choice > category_list.size()) {
      
      std::cin.clear();
      std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
      std::cout << "Invalid choice. Please select a valid category number: ";
      std::cin >> category_choice;
    }
    
    std::string selected_category = category_list[category_choice - 1];
    assignment.setCategory(selected_category);
    
    std::cout << "Please input the points possible for " << assignment_name << ": ";
    std::cin >> assignment_possible;
    
    while (std::cin.fail()) {
      std::cin.clear();
      std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
      std::cout << "Invalid input. Please enter a valid numeric value for "
                   "points possible: ";
      std::cin >> assignment_possible;
    }
    
    assignment.setPointsPossible(assignment_possible);
    std::cout << "Please input the points earned for " << assignment_name << ": ";
    std::cin >> assignment_score;
    
    while (std::cin.fail()) {
      std::cin.clear();
      std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
      std::cout << "Invalid input. Please enter a valid numeric score: ";
      std::cin >> assignment_score;
    }
    assignment.setPointsEarned(assignment_score);
    std::cout << "Is this a bonus assignment? (1 for Yes, 0 for No): ";
    std::cin >> assignment_bonus;
    assignment.setBonus(assignment_bonus);
    assignments.push_back(assignment);
  }
}

void WeightedCalculator::calculateGrade() {
  total_weighted_score = 0.0f;
  std::map<std::string, float> total_earned_points;
  std::map<std::string, float> total_possible_points;
  for (const auto &category : category_weights) {
    total_earned_points[category.first] = 0.0f;
    total_possible_points[category.first] = 0.0f;
  }
  for (const auto &assignment : assignments) {
    float assignment_points_earned = assignment.getPointsEarned();
    if (assignment.isBonus()) {
      total_earned_points[assignment.getCategory()] += assignment_points_earned;
    } else {
      float assignment_points_possible = assignment.getPointsPossible();
      total_possible_points[assignment.getCategory()] +=
          assignment_points_possible;
    }
  }
  for (const auto &category : category_weights) {
    float combined_percentage = 0.0f;
    if (total_possible_points[category.first] != 0) {
      combined_percentage = (total_earned_points[category.first] /
                             total_possible_points[category.first]) *
                            100;
    }
    total_weighted_score +=
        (combined_percentage * category_weights.at(category.first)) / 100;
  }
  if (total_weighted_score >= 90) {
    earned_grade = 'A';
  } else if (total_weighted_score >= 80) {
    earned_grade = 'B';
  } else if (total_weighted_score >= 70) {
    earned_grade = 'C';
  } else if (total_weighted_score >= 60) {
    earned_grade = 'D';
  } else {
    earned_grade = 'F';
  }
}
void WeightedCalculator::displayResults() const {
  std::cout << std::fixed << std::setprecision(2);
  std::cout << "\nWeighted Grade Calculation Results\n";
  std::cout << "--------------------------------\n";
  std::map<std::string, float> regular_points;
  std::map<std::string, float> bonus_points;
  std::map<std::string, float> possible_points;
  for (const auto &category : category_weights) {
    regular_points[category.first] = 0.0f;
    bonus_points[category.first] = 0.0f;
    possible_points[category.first] = 0.0f;
  }
  for (const auto &assignment : assignments) {
    float percentage =
        (assignment.getPointsEarned() / assignment.getPointsPossible()) * 100;
    std::cout << "Assignment: " << assignment.getName()
              << "\n Category: " << assignment.getCategory()
              << "\n Points Earned: " << assignment.getPointsEarned()
              << "\n Points Possible: " << assignment.getPointsPossible()
              << "\n Percentage: " << percentage << "%"
              << "\n Bonus: " << (assignment.isBonus() ? "Yes" : "No")
              << "\n\n";
    if (assignment.isBonus()) {
      bonus_points[assignment.getCategory()] += assignment.getPointsEarned();
    } else {
      regular_points[assignment.getCategory()] += assignment.getPointsEarned();
      possible_points[assignment.getCategory()] +=
          assignment.getPointsPossible();
    }
  }
  std::cout << "Category Summaries:\n";
  for (const auto &category : category_weights) {
    std::cout << category.first << " (Weight: " << category.second << "%)"
              << "\n Regular Points Earned: " << regular_points[category.first]
              << "\n Bonus Points Earned: " << bonus_points[category.first]
              << "\n Total Points (Including Bonus): "
              << (regular_points[category.first] + bonus_points[category.first])
              << "\n Total Possible Points: " << possible_points[category.first]
              << "\n\n";
  }
  std::cout << "Final Weighted Score: " << total_weighted_score << "%"
            << "\nFinal Letter Grade: " << earned_grade << '\n';
}