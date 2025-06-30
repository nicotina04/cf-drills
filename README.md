# 📚 Codeforces Drills  
*A Flutter app that helps you practice Codeforces problems efficiently*  

![](https://img.shields.io/badge/flutter-3.32.4-blue)
![](https://img.shields.io/badge/license-MIT-green)
## Features
![image](https://github.com/user-attachments/assets/4e705a5e-d5f7-4258-a47d-2beefef2ec1d)
- 🎯 **Smart Recommendations**: Get 5 random unsolved problems  
  - Easy, Medium, Challenging, and Set
  
 ![image](https://github.com/user-attachments/assets/f0e639ee-2250-4203-a0a5-513b17507f82)
- 🔥 **One-Click Practice**: Open problems directly in Codeforces
## Installation 
```bash
flutter pub get
flutter run
```
The Windows OS build is released [here](https://github.com/nicotina04/cf-drills/releases/tag/1.0.0%2B1)
## 🎯 Recommendation Logic
- **Model**: XGBoost (trained on Codeforces submission history)  
- **Input Features**: Problem rating, tags, average of user's recent rating changes and etc
- **Source**: [ETL & Training Code](https://github.com/nicotina04/cf-recommender-system)  
## Tech Stack
- Flutter 3.32.4  
- Hive (for local storage)  
- Codeforces API (to fetch data)
