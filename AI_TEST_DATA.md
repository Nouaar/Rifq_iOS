# AI Test Data Guide

Use this data to test the AI features in your app. Add these pets with their medical history and calendar events to see personalized AI tips, status, and reminders.

## Test Pet 1: Luna (Cat)

### Basic Information
- **Name**: Luna
- **Species**: cat
- **Breed**: Persian
- **Age**: 2.5 years
- **Gender**: Female
- **Weight**: 4.2 kg
- **Height**: 25 cm
- **Color**: White

### Medical History
- **Vaccinations**: 
  - FVRCP (Feline Viral Rhinotracheitis, Calicivirus, Panleukopenia)
  - Rabies
  - Feline Leukemia
  
- **Current Medications**:
  - Heartworm Prevention: Monthly
  - Flea & Tick Treatment: Monthly

- **Chronic Conditions**: None

### Calendar Events to Add
1. **Vaccination** (Next week)
   - Title: "Luna - Annual FVRCP Booster"
   - Date: 7 days from now
   - Notes: "Annual vaccination booster due"

2. **Medication Reminder** (Tomorrow)
   - Title: "Luna - Heartworm Prevention"
   - Date: Tomorrow, 8:00 AM
   - Notes: "Give monthly heartworm prevention chewable"
   - Recurring: Monthly

3. **Appointment** (2 weeks from now)
   - Title: "Luna - Annual Health Checkup"
   - Date: 14 days from now, 10:00 AM
   - Notes: "Annual wellness exam and dental cleaning"

---

## Test Pet 2: Max (Dog)

### Basic Information
- **Name**: Max
- **Species**: dog
- **Breed**: Golden Retriever
- **Age**: 5 years
- **Gender**: Male
- **Weight**: 28.5 kg
- **Height**: 60 cm
- **Color**: Golden

### Medical History
- **Vaccinations**:
  - DHPP (Distemper, Hepatitis, Parvovirus, Parainfluenza)
  - Rabies
  - Bordatella
  
- **Current Medications**:
  - Heartworm Prevention: Monthly
  - Joint Supplement: Daily
  - Allergy Medication: Twice daily
  
- **Chronic Conditions**:
  - Hip Dysplasia
  - Seasonal Allergies

### Calendar Events to Add
1. **Medication Reminder** (Today)
   - Title: "Max - Morning Allergy Medication"
   - Date: Today, 8:00 AM
   - Notes: "Give allergy medication with food"
   - Recurring: Daily

2. **Medication Reminder** (Today)
   - Title: "Max - Evening Allergy Medication"
   - Date: Today, 8:00 PM
   - Notes: "Give allergy medication with food"
   - Recurring: Daily

3. **Vaccination** (1 month from now)
   - Title: "Max - Annual Rabies Booster"
   - Date: 30 days from now
   - Notes: "Annual rabies vaccination due"

4. **Appointment** (3 days from now)
   - Title: "Max - Hip Dysplasia Follow-up"
   - Date: 3 days from now, 2:00 PM
   - Notes: "Follow-up appointment for hip dysplasia treatment"

---

## Test Pet 3: Charlie (Dog - Puppy)

### Basic Information
- **Name**: Charlie
- **Species**: dog
- **Breed**: Beagle
- **Age**: 0.5 years (6 months)
- **Gender**: Male
- **Weight**: 8.5 kg
- **Height**: 35 cm
- **Color**: Tri-color

### Medical History
- **Vaccinations**:
  - DHPP (First series - needs booster)
  - Bordatella
  
- **Current Medications**:
  - Puppy Deworming: Weekly (for next 2 weeks)
  
- **Chronic Conditions**: None

### Calendar Events to Add
1. **Vaccination** (5 days from now)
   - Title: "Charlie - DHPP Booster Shot"
   - Date: 5 days from now, 9:00 AM
   - Notes: "Second DHPP vaccination in puppy series"

2. **Medication Reminder** (Today)
   - Title: "Charlie - Deworming Medication"
   - Date: Today, 7:00 AM
   - Notes: "Give deworming medication with breakfast"
   - Recurring: Weekly

3. **Reminder** (Tomorrow)
   - Title: "Charlie - Socialization Training"
   - Date: Tomorrow, 3:00 PM
   - Notes: "Puppy socialization class at dog park"

---

## Test Pet 4: Bella (Cat - Senior)

### Basic Information
- **Name**: Bella
- **Species**: cat
- **Breed**: Siamese
- **Age**: 12 years
- **Gender**: Female
- **Weight**: 3.8 kg
- **Height**: 23 cm
- **Color**: Seal Point

### Medical History
- **Vaccinations**:
  - FVRCP (Up-to-date)
  - Rabies (Up-to-date)
  
- **Current Medications**:
  - Kidney Support Supplement: Twice daily
  - Arthritis Medication: Daily
  
- **Chronic Conditions**:
  - Chronic Kidney Disease (Stage 2)
  - Arthritis

### Calendar Events to Add
1. **Medication Reminder** (Today)
   - Title: "Bella - Morning Kidney Support"
   - Date: Today, 7:00 AM
   - Notes: "Give kidney support supplement with wet food"
   - Recurring: Daily

2. **Medication Reminder** (Today)
   - Title: "Bella - Evening Kidney Support"
   - Date: Today, 7:00 PM
   - Notes: "Give kidney support supplement with wet food"
   - Recurring: Daily

3. **Appointment** (1 week from now)
   - Title: "Bella - Kidney Function Test"
   - Date: 7 days from now, 11:00 AM
   - Notes: "Quarterly blood work to monitor kidney function"

4. **Reminder** (3 days from now)
   - Title: "Bella - Weight Check"
   - Date: 3 days from now
   - Notes: "Monthly weight monitoring for CKD management"

---

## Expected AI Responses

### For Luna (Healthy Adult Cat)
- **Tips**: Should mention regular grooming (Persian), dental care, exercise
- **Status**: "Healthy" or "Up-to-date"
- **Reminders**: Heartworm prevention, upcoming vaccination

### For Max (Dog with Conditions)
- **Tips**: Should mention joint care (hip dysplasia), allergy management, exercise moderation
- **Status**: "On Medication" or "Needs Attention"
- **Reminders**: Daily allergy medication, upcoming appointment, vaccination due

### For Charlie (Puppy)
- **Tips**: Should mention puppy-specific care, training, socialization, vaccination schedule
- **Status**: "Growing" or "Needs Vaccines"
- **Reminders**: Deworming schedule, upcoming vaccination, training

### For Bella (Senior Cat with CKD)
- **Tips**: Should mention kidney-friendly diet, hydration, senior care, monitoring
- **Status**: "Needs Attention" or "On Medication"
- **Reminders**: Daily medications, upcoming tests, weight monitoring

---

## Testing Checklist

1. ✅ Add pets with the above information
2. ✅ Add calendar events for each pet
3. ✅ Check HomeView for AI-generated tips (should show "Tips about Luna", "Tips about Max", etc.)
4. ✅ Verify status pills are dynamic (not just "Healthy")
5. ✅ Check reminders combine calendar events + AI suggestions
6. ✅ Test with different medical histories (some with medications, some without)
7. ✅ Test with pets that have upcoming calendar events vs. those without
8. ✅ Verify tips change based on pet's age, breed, and medical conditions

---

## Quick Test Scenarios

### Scenario 1: Healthy Pet with No Events
- Add a pet with complete vaccinations, no medications, no calendar events
- **Expected**: AI should suggest preventive care, general wellness tips

### Scenario 2: Pet with Chronic Condition
- Add Max (with hip dysplasia and allergies)
- **Expected**: AI should focus on condition management, medication adherence

### Scenario 3: Puppy Needing Vaccines
- Add Charlie (incomplete vaccination series)
- **Expected**: AI should emphasize vaccination schedule, puppy care

### Scenario 4: Senior Pet
- Add Bella (with CKD and arthritis)
- **Expected**: AI should focus on senior care, monitoring, comfort

---

## Tips for Best AI Results

1. **Complete Medical History**: The more information you provide, the better the AI recommendations
2. **Add Calendar Events**: Events help AI understand upcoming needs
3. **Be Specific**: Include breed, age, and weight for breed-specific advice
4. **Update Regularly**: Keep medical history and calendar up-to-date for accurate AI suggestions

---

## Notes

- AI responses may vary slightly each time (this is normal)
- First load may take a few seconds as AI generates content
- If API key is missing, the app will fall back to static content
- Make sure calendar access is granted for calendar-aware features

