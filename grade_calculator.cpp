#include <string>
extern "C" {
    #include "include/lua5.1/lua.h"
    #include "include/lua5.1/lauxlib.h"
    #include "include/lua5.1/lualib.h"
    }
    
class GradeCalculator {
private:
    double totalPoints;
    double minA, minB, minC, minD;
public:
    void setGradingScheme(double tp, double a, double b, double c, double d) {
        totalPoints = tp;
        minA = a;
        minB = b;
        minC = c;
        minD = d;
    }
    char calculateGrade(double pointsEarned) {
        if (pointsEarned >= minA) return 'A';
        else if (pointsEarned >= minB) return 'B';
        else if (pointsEarned >= minC) return 'C';
        else if (pointsEarned >= minD) return 'D';
        else return 'F';
    }
};

static GradeCalculator calculator;

extern "C" {

int set_grading_scheme(lua_State* L) {
    double totalPoints = luaL_checknumber(L, 1);
    double minA = luaL_checknumber(L, 2);
    double minB = luaL_checknumber(L, 3);
    double minC = luaL_checknumber(L, 4);
    double minD = luaL_checknumber(L, 5);
    calculator.setGradingScheme(totalPoints, minA, minB, minC, minD);
    return 0; // No return values
}

int calculate_grade(lua_State* L) {
    double pointsEarned = luaL_checknumber(L, 1);
    char grade = calculator.calculateGrade(pointsEarned);
    lua_pushstring(L, std::string(1, grade).c_str());
    return 1; // One return value (the grade)
}

int luaopen_grade_calculator(lua_State* L) {
    lua_newtable(L);
    lua_pushcfunction(L, set_grading_scheme);
    lua_setfield(L, -2, "set_grading_scheme");
    lua_pushcfunction(L, calculate_grade);
    lua_setfield(L, -2, "calculate_grade");
    return 1; // Return the table
}

}