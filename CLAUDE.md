# Running Log Diary

## Overview
- **Goal**: Manage daily running logs and condition tracking
- **Core Design**: Built with predictable state management and modularized features based on TCA.
- **Key Concept**: Focused on clear state–action boundaries and data-driven UI updates.

## Tech Stack
- **Architecture**: TCA (@Reducer, State, Action, Dependency)
- **Storage**: SwiftData (Repository pattern)
- **Integration**: HealthKit (distance/heart rate/cadence/route), Shoes API, Weather API

## Main Screens
1. **Daily Logs** (Main): Date carousel, HealthKit data, pain/stride/condition, shoes, weather, route
2. **Calendar View**: Satisfaction visualization
3. **Add/Edit Log**: Import from HealthKit or manual entry

## Priorities
1. ✅ Setup
2. 🔄 Basic UI structure (date carousel, mock data)
3. ⏳ HealthKit integration
4. ⏳ Log entry screen
5. ⏳ Calendar view
6. ⏳ SwiftData + Repository
7. ⏳ External API integration

## Coding Guidelines
- **Naming**: SwiftLint + Swift API Guidelines
  - Types: UpperCamelCase (`~View`, `~Feature`)
  - Variables/functions: lowerCamelCase
- **TCA**: `@Reducer` macro, separate State/Action, `@Dependency` injection
- **Access Control**: default internal, private when unnecessary
- **Testing**: Reducers must use TestStore, Dependencies require mock implementations

See existing feature files for detailed examples

## Collaboration
Git workflow, commit/PR conventions: [CONTRIBUTING.md](./CONTRIBUTING.md)