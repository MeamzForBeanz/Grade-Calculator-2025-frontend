
#include <iostream>
#include <sstream>
#include <map>
#include <vector>
#include <string>
#include "include/assignment.h"
#include "include/weighted_assignment.h"
#include "include/unweighted_calculator.h"
#include "include/weighted_calculator.h"

extern "C" {
  #include "include/lua5.1/lua.h"
  #include "include/lua5.1/lauxlib.h"
  #include "include/lua5.1/lualib.h"
  }


// Function to run the calculator and capture output
std::string run_calculator(char choice, lua_State* L, int index) {
    std::ostringstream oss;
    std::streambuf* old_cout = std::cout.rdbuf(oss.rdbuf()); // Redirect cout

    Calculator* calculator = nullptr;

    if (choice == '1') { // Unweighted Calculator
        UnweightedCalculator* unweighted = new UnweightedCalculator();
        calculator = unweighted;

        // Set grading scheme from Lua inputs
        int total_points = luaL_checkinteger(L, index);
        float A_points = luaL_checknumber(L, index + 1);
        float B_points = luaL_checknumber(L, index + 2);
        float C_points = luaL_checknumber(L, index + 3);
        float D_points = luaL_checknumber(L, index + 4);
        unweighted->setGradingScheme(total_points, A_points, B_points, C_points, D_points);

        // Add assignments from Lua table
        luaL_checktype(L, index + 5, LUA_TTABLE);
        int len = lua_objlen(L, index + 5);
        for (int i = 1; i <= len; i++) {
            lua_rawgeti(L, index + 5, i);
            lua_rawgeti(L, -1, 1); // name
            std::string name = luaL_checkstring(L, -1);
            lua_pop(L, 1);
            lua_rawgeti(L, -1, 2); // points_possible
            float points_possible = luaL_checknumber(L, -1);
            lua_pop(L, 1);
            lua_rawgeti(L, -1, 3); // points_earned
            float points_earned = luaL_checknumber(L, -1);
            lua_pop(L, 1);
            lua_rawgeti(L, -1, 4); // is_bonus
            bool is_bonus = lua_toboolean(L, -1);
            lua_pop(L, 2); // Pop is_bonus and assignment table

            Assignment assignment;
            assignment.setName(name);
            assignment.setPointsPossible(points_possible);
            assignment.setPointsEarned(points_earned);
            assignment.setBonus(is_bonus);
            unweighted->addAssignment(assignment);
        }
    } else if (choice == '2') { // Weighted Calculator
        WeightedCalculator* weighted = new WeightedCalculator();
        calculator = weighted;

        // Set grading scheme from Lua table
        luaL_checktype(L, index, LUA_TTABLE);
        std::map<std::string, float> category_weights;
        lua_pushnil(L);
        while (lua_next(L, index) != 0) {
            std::string category = luaL_checkstring(L, -2);
            float weight = luaL_checknumber(L, -1);
            category_weights[category] = weight;
            lua_pop(L, 1);
        }
        weighted->setGradingScheme(category_weights);

        // Add assignments from Lua table
        luaL_checktype(L, index + 1, LUA_TTABLE);
        int len = lua_objlen(L, index + 1);
        for (int i = 1; i <= len; i++) {
            lua_rawgeti(L, index + 1, i);
            lua_rawgeti(L, -1, 1); // name
            std::string name = luaL_checkstring(L, -1);
            lua_pop(L, 1);
            lua_rawgeti(L, -1, 2); // category
            std::string category = luaL_checkstring(L, -1);
            lua_pop(L, 1);
            lua_rawgeti(L, -1, 3); // points_possible
            float points_possible = luaL_checknumber(L, -1);
            lua_pop(L, 1);
            lua_rawgeti(L, -1, 4); // points_earned
            float points_earned = luaL_checknumber(L, -1);
            lua_pop(L, 1);
            lua_rawgeti(L, -1, 5); // is_bonus
            bool is_bonus = lua_toboolean(L, -1);
            lua_pop(L, 2); // Pop is_bonus and assignment table

            WeightedAssignment assignment;
            assignment.setName(name);
            assignment.setCategory(category);
            assignment.setPointsPossible(points_possible);
            assignment.setPointsEarned(points_earned);
            assignment.setBonus(is_bonus);
            weighted->addAssignment(assignment);
        }
    } else {
        std::cout << "Invalid choice.\n";
        std::cout.rdbuf(old_cout);
        return oss.str();
    }

    calculator->calculateGrade();
    calculator->displayResults();
    delete calculator;

    std::cout.rdbuf(old_cout); // Restore cout
    return oss.str();
}

// Lua binding function
static int lua_run_calculator(lua_State* L) {
    char choice = luaL_checkinteger(L, 1) == 2 ? '2' : '1';
    std::string result = run_calculator(choice, L, 2);
    lua_pushstring(L, result.c_str());
    return 1;
}

static const struct luaL_Reg grade_calculator_lib[] = {
    {"run_calculator", lua_run_calculator},
    {NULL, NULL}
};

extern "C" int luaopen_grade_calculator(lua_State* L) {
    luaL_register(L, "grade_calculator", grade_calculator_lib);
    return 1;
}