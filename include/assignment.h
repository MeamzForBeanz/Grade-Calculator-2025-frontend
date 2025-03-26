#ifndef ASSIGNMENT_H
#define ASSIGNMENT_H
#include <string>
class Assignment
{
private:
    std::string name;
    float points_possible;
    float points_earned;
    bool bonus;
    static int total_assignments;

public:
    // Default constructor
    Assignment();
    // Setters
    void setName(const std::string &name);
    void setPointsPossible(float points_possible);
    void setPointsEarned(float points_earned);
    void setBonus(bool bonus);
    // Getters
    std::string getName() const;
    float getPointsPossible() const;
    float getPointsEarned() const;
    bool isBonus() const;
    static int getTotalAssignments();
};
#endif // ASSIGNMENT_H