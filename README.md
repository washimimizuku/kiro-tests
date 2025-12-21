# Kiro Testing Ground

A comprehensive testing repository for exploring [Kiro CLI](https://kiro.ai) and Kiro IDE capabilities across diverse programming languages, frameworks, and project architectures.

## 🎯 Purpose

This repository serves as a practical testing ground to evaluate Kiro's AI-powered development assistance across different technology stacks and project types. Each project demonstrates Kiro's capabilities in:

- **Code Generation & Refactoring** - AI-assisted development workflows
- **Multi-language Support** - Testing across various programming languages
- **Architecture Patterns** - From simple scripts to complex microservices
- **Testing Strategies** - Unit tests, integration tests, and property-based testing
- **Documentation Generation** - Automated documentation and README creation
- **Project Scaffolding** - Rapid project setup and structure generation

## 🚀 Projects Overview

### Backend & API Development

#### **Country Data API** 
- **Languages**: Python, Rust
- **Frameworks**: FastAPI, Axum
- **Features**: REST API, data validation, property-based testing
- **Directories**: `country-data-api/`, `country-data-api-rust/`, `country-data-api-rust-kiro/`

#### **Work Tracker** 
- **Languages**: TypeScript, Python
- **Frameworks**: React, FastAPI
- **Architecture**: Microservices with AWS integration
- **Features**: Full-stack web application, AI integration (AWS Bedrock), authentication
- **Directory**: `work-tracker/`

### Full-Stack Ecosystem

#### **Bird Watching Platform** 
- **Architecture**: Complete multi-platform ecosystem with 3 integrated applications
- **Directory**: `my-birds/`

**Backend Service** (`bird-watching-backend/`)
- **Language**: Rust
- **Framework**: Actix-web
- **Database**: PostgreSQL with SQLx
- **Features**: REST API, JWT authentication, geolocation services, file uploads
- **Testing**: Property-based testing with proptest

**Web Application** (`bird-watching-frontend/`)
- **Language**: TypeScript
- **Framework**: React 19 with Vite
- **Mapping**: Leaflet with marker clustering
- **Features**: Interactive maps, GPS integration, responsive design
- **Testing**: Vitest with fast-check property testing

**Mobile Application** (`bird-watching-mobile/`)
- **Language**: Dart
- **Framework**: Flutter (iOS/Android)
- **Architecture**: Clean Architecture with BLoC pattern
- **Features**: Offline-first, camera integration, GPS tracking, secure storage
- **Testing**: Unit, widget, and integration tests

### CLI & System Tools

#### **Rust Calculator**
- **Language**: Rust
- **Type**: Command-line application
- **Features**: Mathematical operations, CLI argument parsing
- **Directory**: `rust-calculator/`

### Productivity & Tracking

#### **Professional Activity Tracker**
- **Language**: Python
- **Type**: Productivity tool with reporting
- **Features**: Activity logging, report generation, data analysis
- **Directory**: `professional-activity-tracker/`

## 🛠 Technology Stack Coverage

### Programming Languages
- **Python** - FastAPI, data processing, CLI tools
- **Rust** - High-performance APIs, system programming
- **TypeScript** - Frontend applications, Node.js backends
- **JavaScript** - Web development, React applications
- **Dart** - Flutter mobile applications

### Frameworks & Libraries
- **Backend**: FastAPI, Actix-web, Axum, Express.js
- **Frontend**: React, Flutter
- **Mobile**: Flutter (iOS/Android), BLoC pattern, Clean Architecture
- **Mapping**: Leaflet, Google Maps, marker clustering
- **Testing**: pytest, Hypothesis, Vitest, fast-check, proptest
- **Databases**: PostgreSQL, SQLite, SQLx
- **Cloud**: AWS (Bedrock, Cognito, ECS, S3)

### Architecture Patterns
- **Microservices** - Distributed service architectures (Work Tracker)
- **Monolithic** - Single-service applications (Country Data APIs)
- **Full-stack** - Integrated frontend/backend solutions (Work Tracker)
- **Multi-platform Ecosystem** - Complete platform with web, mobile, and API (Bird Watching)
- **Mobile-first** - Cross-platform mobile applications with offline support
- **CLI Tools** - Command-line utilities and scripts

## 📁 Repository Structure

```
kiro-tests/
├── country-data-api/              # Python FastAPI REST API
├── country-data-api-rust/         # Rust Axum equivalent
├── country-data-api-rust-kiro/    # Kiro-enhanced Rust version
├── work-tracker/                  # Full-stack TypeScript/Python app
├── my-birds/                      # Multi-platform bird watching ecosystem
│   ├── bird-watching-backend/     # Rust Actix-web API service
│   ├── bird-watching-frontend/    # React TypeScript web app
│   └── bird-watching-mobile/      # Flutter mobile app (iOS/Android)
├── rust-calculator/               # Rust CLI application
├── professional-activity-tracker/ # Python productivity tool
└── README.md                      # This file
```

## 🧪 Testing Methodologies

Each project explores different testing approaches with Kiro:

### Property-Based Testing
- **Python**: Hypothesis library integration
- **Rust**: proptest framework usage  
- **TypeScript**: fast-check implementation
- **Testing Strategy**: Automated test case generation and edge case discovery

### Unit & Integration Testing
- **Comprehensive Coverage**: Core functionality validation
- **API Testing**: Endpoint behavior verification
- **UI Testing**: Component and user interaction testing

### Performance Testing
- **Load Testing**: API performance under stress
- **Benchmark Testing**: Algorithm and data structure optimization
- **Memory Profiling**: Resource usage analysis

## 🎯 Kiro Evaluation Criteria

### Code Quality
- **Consistency**: Adherence to language-specific best practices
- **Readability**: Clear, maintainable code generation
- **Performance**: Efficient algorithm and pattern suggestions

### Development Velocity
- **Setup Speed**: Project initialization and scaffolding
- **Feature Development**: End-to-end feature implementation
- **Debugging Assistance**: Error identification and resolution

### Cross-Language Capabilities
- **Pattern Recognition**: Consistent architectural patterns across languages
- **Best Practices**: Language-specific optimization suggestions
- **Documentation**: Automated documentation generation quality

## 🚀 Getting Started

### Prerequisites
- **Kiro CLI/IDE** - [Installation Guide](https://kiro.ai)
- **Language Runtimes**: Python 3.11+, Rust 1.70+, Node.js 18+, Flutter SDK
- **Development Tools**: Docker, Git, VS Code (optional)

### Quick Start
1. **Clone Repository**
   ```bash
   git clone https://github.com/washimimizuku/kiro-tests.git
   cd kiro-tests
   ```

2. **Explore Projects**
   ```bash
   # Python FastAPI example
   cd country-data-api && python -m venv venv && source venv/bin/activate
   pip install -r requirements.txt && uvicorn app:app --reload
   
   # Rust API example  
   cd country-data-api-rust && cargo run
   
   # Full-stack application
   cd work-tracker && docker-compose up
   
   # Multi-platform bird watching ecosystem
   cd my-birds
   
   # Start backend (Rust Actix-web)
   cd bird-watching-backend && cargo run
   
   # Start web frontend (React + Leaflet maps)
   cd ../bird-watching-frontend && npm install && npm run dev
   
   # Run mobile app (Flutter)
   cd ../bird-watching-mobile && flutter run
   ```

3. **Run Tests**
   ```bash
   # Python property-based tests
   cd country-data-api && pytest tests/test_properties.py
   
   # Rust property tests
   cd country-data-api-rust && cargo test
   
   # TypeScript tests with fast-check
   cd work-tracker/frontend && npm test
   
   # Multi-platform ecosystem tests
   cd my-birds
   
   # Backend property tests (Rust proptest)
   cd bird-watching-backend && cargo test
   
   # Frontend tests (React + fast-check)
   cd ../bird-watching-frontend && npm test
   
   # Mobile tests (Flutter)
   cd ../bird-watching-mobile && flutter test
   ```

## 📊 Project Status

| Project | Language(s) | Status | Kiro Features Tested |
|---------|-------------|--------|---------------------|
| Country Data API | Python | ✅ Complete | API generation, testing, documentation |
| Country Data API (Rust) | Rust | ✅ Complete | Cross-language porting, property testing |
| Work Tracker | TypeScript/Python | 🚧 In Progress | Full-stack development, AI integration |
| **Bird Watching Platform** | **Multi-platform** | ✅ **Complete** | **Ecosystem development, cross-platform** |
| ├─ Backend Service | Rust | ✅ Complete | API development, geolocation, file handling |
| ├─ Web Application | TypeScript/React | ✅ Complete | Interactive maps, responsive design |
| └─ Mobile Application | Dart/Flutter | ✅ Complete | Offline-first, camera, GPS, clean architecture |
| Rust Calculator | Rust | ✅ Complete | CLI development, argument parsing |
| Activity Tracker | Python | ✅ Complete | Data processing, report generation |

## 🤝 Contributing

This repository is primarily for Kiro testing and evaluation. However, contributions that help improve the testing scenarios are welcome:

1. **New Project Types** - Additional language/framework combinations
2. **Testing Scenarios** - Novel use cases for Kiro evaluation
3. **Documentation** - Improved setup and usage instructions
4. **Bug Reports** - Issues encountered during Kiro testing

## 📝 License

This project is licensed under the MIT License - see individual project directories for specific licensing information.

## 🔗 Resources

- **Kiro Official Website**: [https://kiro.ai](https://kiro.ai)
- **Kiro Documentation**: [https://docs.kiro.ai](https://docs.kiro.ai)
- **Community**: [Kiro Discord/Forum](https://kiro.ai/community)

---

**Note**: This repository is maintained for testing and evaluation purposes. Individual projects may have different maturity levels and are not intended for production use without proper review and testing.
