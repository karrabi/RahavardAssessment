# RahavardAssessment

This project implements a flexible personnel management system using a dynamic attribute-based database architecture. The implementation follows the requirements specified in `پروژه دیتابیسی.pdf`, focusing on extensibility and maintainable data management.

## Repository Structure

The project is organized into several key components, each serving a specific purpose in the system:

### Documentation
The `Documentation` folder contains comprehensive design materials:
- A UML Class Diagram that visualizes the relationships between database entities and their attributes
- A `draft` subfolder containing preliminary design sketches and documentation that showcase the evolution of the system architecture

### SQL Implementation Files
- `tables.sql`: Contains the complete database schema definition, including all table structures, relationships, and constraints necessary for the dynamic attribute system
- `storedprocedure_managing.sql`: Implements the core business logic through stored procedures that handle attribute management, personnel data operations, and system maintenance
- `storedprocedures_reports.sql`: Provides sample reporting capabilities through stored procedures, demonstrating how to effectively query and present the dynamic attribute data
- `functions.sql`: Implements specialized functions, including the age calculation function that operates on the dynamic attribute structure

## Implementation Details

### Design Decisions

The system architecture is built on several key design principles:

1. CMS-Based Architecture
   The implementation follows Content Management System best practices for handling dynamic attributes. This approach allows for flexible attribute definition and management without requiring database schema modifications when new attributes are needed.

2. Formula Management
   A dedicated formula storage table has been implemented to maintain calculated attributes separately from basic attributes. This separation provides better maintainability and allows for complex calculations while keeping the core attribute structure clean.

3. Age Calculation
   The system implements age calculation through a dedicated function that accepts a PersonnelID parameter. This approach ensures consistent age calculations throughout the system while maintaining the flexibility to modify the calculation logic in a single location.

### Design Suggestions

The implementation can includes several recommended enhancements to improve data management and historical tracking:

1. Logical Deletion in Personnel Table
   Rather than physically removing personnel records, the system should implement a `deleted` flag in the Personnel table. This approach preserves referential integrity and allows for potential record restoration if needed.

2. Historical Data Management
   Adding a `deleted` flag to the AttributeValues table enables historical data tracking. This design allows the system to maintain a complete history of attribute changes while still presenting only current values in standard queries.

### Performance Considerations

The implementation can includes several features to ensure efficient system operation:

1. Formula Value Management
   The `sp_CalculateFormulaValues` stored procedure should be executed before running reports to ensure all calculated values are up-to-date. This approach balances computation efficiency with data accuracy.

2. Query Optimization
   Report execution is optimized through carefully designed constraints. For example, the `sp_GetDynamicPersonnelReport` uses a `@MonthsBack` parameter to limit the data range, preventing resource-intensive queries from impacting system performance.

This implementation provides a robust foundation for personnel data management while maintaining flexibility for future enhancements and modifications. The design choices prioritize data integrity, system performance, and maintainability, making the system suitable for long-term use and evolution.