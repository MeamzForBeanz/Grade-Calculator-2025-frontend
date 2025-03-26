#include "assignment.h"
int Assignment::total_assignments = 0;

Assignment::Assignment()
    : name(""), points_possible(0.0f), points_earned(0.0f), bonus(false)
{
    ++total_assignments;
}
// Setters
void Assignment::setName(const std::string &name)
{
    this->name = name;
}
void Assignment::setPointsPossible(float points_possible)
{
    this->points_possible = points_possible;
}
void Assignment::setPointsEarned(float points_earned)
{
    this->points_earned = points_earned;
}
void Assignment::setBonus(bool bonus)
{
    this->bonus = bonus;
}
// Getters
std::string Assignment::getName() const
{
    return name;
}
float Assignment::getPointsPossible() const
{
    return points_possible;
}
float Assignment::getPointsEarned() const
{
    return points_earned;
}
bool Assignment::isBonus() const
{
    return bonus;
}
int Assignment::getTotalAssignments()
{
    return total_assignments;
}