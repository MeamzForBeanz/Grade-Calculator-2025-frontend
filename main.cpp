#include "include/unweighted_calculator.h"
#include "include/weighted_calculator.h"
#include <iostream>
#include <map>

extern "C" {
  #include "include/lua5.1/lua.h"
  #include "include/lua5.1/lauxlib.h"
  #include "include/lua5.1/lualib.h"
  }


int main() {
  std::cout << "Welcome to Hayden Phillip's Grade Calculator\n\n";
    
  Calculator *calculator = nullptr;
  char choice;
    
  std::cout << "Choose calculator type:\n";
  std::cout << "1. Unweighted (standard points-based)\n";
  std::cout << "2. Weighted (category-based)\n";
  std::cout << "Enter choice (1 or 2): ";
  std::cin >> choice;
    
  if (choice == '2') {
    calculator = new WeightedCalculator();
    std::map<std::string, float> category_weights;
    int num_categories;
    std::cout << "\nHow many grade categories do you have? ";
    std::cin >> num_categories;
      
    for (int i = 0; i < num_categories; i++) {
      std::string category;
      float weight;
      std::cout << "Enter category name " << (i + 1) << ": ";
      std::cin >> std::ws;
      std::getline(std::cin, category);
      std::cout << "Enter weight for " << category << " (in %): ";
      std::cin >> weight;
      category_weights[category] = weight;
    }
      
    static_cast<WeightedCalculator *>(calculator)
        ->setGradingScheme(category_weights);
      
  } else {
    calculator = new UnweightedCalculator();
    int total_points;
    float A_points, B_points, C_points, D_points;
    std::cout << "Enter total course points: ";
    std::cin >> total_points;
    std::cout << "Enter minimum points needed for an A: ";
    std::cin >> A_points;
    std::cout << "Enter minimum points needed for a B: ";
    std::cin >> B_points;
    std::cout << "Enter minimum points needed for a C: ";
    std::cin >> C_points;
    std::cout << "Enter minimum points needed for a D: ";
    std::cin >> D_points;
    static_cast<UnweightedCalculator *>(calculator)
        
        ->setGradingScheme(total_points, A_points, B_points, C_points,
                           D_points);
  }
    
  calculator->inputAssignments();
  calculator->calculateGrade();
  calculator->displayResults();
  delete calculator;
  return 0;
}