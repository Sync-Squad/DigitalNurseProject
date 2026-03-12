# Plan Adherence Tracking System - Testing Guide

## ✅ Implementation Status
All features have been implemented and are ready for testing!

## 🧪 How to Test the Features

### 1. **Plan-Generated Log Indicators**

**What to Test:**
- Logs created from plans should show a "Plan" badge

**Steps:**
1. Open the app and navigate to **Lifestyle** tab
2. Go to **Plans** (tap the "Plans" button)
3. Create a new diet or exercise plan (or use an existing one)
4. Tap **"Apply"** on a plan to generate logs
5. Go back to the **Diet/Exercise Log** screen
6. **Expected:** Logs created from the plan should show a small "Plan" badge with a calendar icon next to the meal/activity type

**Where to See:**
- **Diet/Exercise Log Screen**: Plan badges appear next to meal/activity names
- **Dashboard**: Plan badges appear in the diet/exercise sections

---

### 2. **Compliance Screen**

**What to Test:**
- View compliance metrics for applied plans
- See calendar view, daily breakdown, and detailed comparison

**Steps:**
1. Navigate to **Lifestyle** → **Plans**
2. Find a plan that has been applied (has logs)
3. Tap the **"Compliance"** button on the plan card
4. **Expected:** You should see:
   - Overall compliance percentage at the top
   - Date range selector (7 days, 30 days, Custom)
   - Three view tabs: Calendar, Daily, Detailed

**Calendar View:**
- Shows a monthly calendar with color-coded days
- Green = High compliance (≥80%)
- Orange = Medium compliance (50-79%)
- Red = Low compliance (<50%)
- Tap a day to see details

**Daily Breakdown View:**
- Lists each day with compliance percentage
- Tap a day to expand and see:
  - Planned items vs Actual items
  - Matched items (highlighted in green)
  - Missing items (highlighted in red)
  - Extra items (highlighted in gray)

**Detailed Comparison View:**
- Side-by-side comparison of Planned vs Actual
- Shows which items matched (green checkmark)
- Shows which items are missing or extra

---

### 3. **Backend API Endpoints**

**Test Compliance API:**
```bash
# Get diet plan compliance (last 7 days)
GET /lifestyle/diet-plans/{planId}/compliance

# Get diet plan compliance (custom date range)
GET /lifestyle/diet-plans/{planId}/compliance?startDate=2024-01-01&endDate=2024-01-31

# Get exercise plan compliance
GET /lifestyle/exercise-plans/{planId}/compliance
```

**Response Format:**
```json
{
  "planId": "123",
  "period": {
    "startDate": "2024-01-01",
    "endDate": "2024-01-07"
  },
  "overallCompliance": 85.5,
  "dailyBreakdown": [
    {
      "date": "2024-01-01",
      "planned": 3,
      "actual": 3,
      "matched": 3,
      "compliance": 100.0,
      "details": [...]
    }
  ]
}
```

---

### 4. **Database Verification**

**Check if sourcePlanId is being set:**
```sql
-- Check diet logs with plan source
SELECT diet_id, log_date, meal_type, food_items, source_plan_id 
FROM diet_logs 
WHERE source_plan_id IS NOT NULL;

-- Check exercise logs with plan source
SELECT exercise_id, log_date, exercise_type, description, source_plan_id 
FROM exercise_logs 
WHERE source_plan_id IS NOT NULL;
```

---

## 🔍 Troubleshooting

### Issue: Plan badges not showing
**Check:**
1. Verify the plan was applied (logs were created)
2. Check if `sourcePlanId` is in the API response
3. Verify the mapper includes `sourcePlanId` (✅ Fixed)

### Issue: Compliance screen shows 0% or no data
**Check:**
1. Ensure the plan has been applied
2. Verify there are actual logs for the selected date range
3. Check backend logs for API errors

### Issue: Compliance calculation seems wrong
**Note:** Compliance matches by:
- Same date
- Same mealType/activityType
- Manual logs that match plan items also count toward compliance

---

## 📱 Quick Test Checklist

- [ ] Create a diet plan with meals for different days
- [ ] Apply the plan (creates logs)
- [ ] Verify "Plan" badges appear on logs
- [ ] Navigate to Compliance screen
- [ ] Check overall compliance percentage
- [ ] View Calendar view
- [ ] View Daily breakdown
- [ ] View Detailed comparison
- [ ] Test with exercise plan (same steps)
- [ ] Verify dashboard shows plan indicators

---

## 🎯 Key Features Summary

1. **Plan Tracking**: Logs created from plans have `sourcePlanId` set
2. **Visual Indicators**: "Plan" badges on logs from plans
3. **Compliance Metrics**: Overall and daily compliance percentages
4. **Calendar View**: Visual calendar with color-coded compliance
5. **Daily Breakdown**: Expandable day-by-day details
6. **Detailed Comparison**: Side-by-side planned vs actual comparison
7. **API Endpoints**: RESTful endpoints for compliance data

---

## 🚀 Next Steps

After testing, you can:
- Customize compliance calculation logic (fuzzy matching, description similarity)
- Add notifications for low compliance
- Export compliance reports
- Add compliance trends over time

